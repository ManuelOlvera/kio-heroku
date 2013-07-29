class Ground < ActiveRecord::Base
    attr_accessible :groundName, :recordId, :latitude, :longitude, :last_modified_date

    geocoded_by         :full_street_address
    reverse_geocoded_by :latitude, :longitude
    # after_validation    :geocode
    # after_validation    :reverse_geocode

    # get the grounds from salesforce | https://<instance_url>/services/apexrest/kio/v1.0/getGrounds?lat=null&lng=null
    def self.get_grounds_from_salesforce
    	begin

			# prepare call
			endpoint = '/kio/v1.0/getGrounds'
			params   = '?' + 'lat=' + 'null' + '&lng=' + 'null'
			url      = @@client.instance_url + '/services/apexrest' + endpoint + params

			# log
			puts '> get grounds from salesforce:' + url

			# http call
			result   = @@client.http_get( url )

			puts '>>>>>>>>>>>>>>>>>>>>>>>>>>>>> result get grounds from salesforce:' + result.body

			# log
			# puts '> get grounds call result: ' + result.body

			if result.body.length != 0
				# deserialize
				parsed_json = ActiveSupport::JSON.decode(result.body)	#ActiveSuppor:: not required because already in the framework
				# transform to array with '=>'' instad of ':''
				@result_record_list = JSON.parse(parsed_json)

				# insert or update new records
				self.insert_update_grounds

				# delete local records removed from the server
				self.delete_deleted_grounds
			end


		rescue Databasedotcom::SalesForceError => e
			puts '> error getting grounds ' + e.message
		end
    end

    def self.insert_update_grounds
    	###############################################################################
		# insert - update
		###############################################################################

		# ids array for delete
		@remote_server_record_ids = []
		# create an record for each element of the array
		@result_record_list.each do |remote_record|
			# build remote recordIds array
			@remote_server_record_ids<<remote_record['Id']
			# search if ground it's already present => if not save it
			local_record = self.find_by_recordId(remote_record['Id'])

			if local_record == nil
				# create a new ground using the model attribs
				new_ground = Ground.new(:recordId => remote_record['Id'],
					                    :groundName => remote_record['Name'],
					                    :latitude => remote_record['Geolocation__Latitude__s'],
					                    :longitude => remote_record['Geolocation__Longitude__s'],
										:last_modified_date => remote_record['LastModifiedDate'])
				new_ground.save
				# log
				puts '> saved ground ' + remote_record['Name']
			else

				# if local_record[:last_modified_date] < ActiveSupport::TimeZone['UTC'].parse(remote_record['LastModifiedDate'])
				# 	puts '> update ground'
				# 	puts 'REMOTE ' + remote_record['Name'] + ' ' + ActiveSupport::TimeZone['UTC'].parse(remote_record['LastModifiedDate']).to_s
				# 	puts 'LOCAL ' + local_record[:groundName] + ' ' + local_record[:last_modified_date].to_s
				# else
				# 	puts 'COMPARISON false'
				# end

				if local_record[:last_modified_date] < ActiveSupport::TimeZone['UTC'].parse( remote_record['LastModifiedDate'] )
					# has been updated => update it
					local_record.update_attributes!(:groundName => remote_record['Name'],
													:latitude => remote_record['Geolocation__Latitude__s'],
													:longitude => remote_record['Geolocation__Longitude__s'],
													:last_modified_date => remote_record['LastModifiedDate'])
					# log
					puts '> updated ground ' + local_record[:groundName]
				end
			end
		end
    end

    def self.delete_deleted_grounds
	    ###############################################################################
		# delete
		###############################################################################

		# search for removed (or unpublished) records
		local_record_list = Ground.all
		result_record_list_size = @result_record_list.length
		local_record_list_size  = local_record_list.length

		# if local records number not greater than remote we don't have to delete
		if local_record_list_size > result_record_list_size
			# local recordIds array with parallel internal record ids array
			local_server_record_ids  = []       # remote_server_record_ids generated before
			local_internal_record_ids = []		# parallelal hash structure to save corrispondent internal id for fast delete
			local_record_list.each do |local_record|
				local_server_record_ids<<local_record[:recordId]
				local_internal_record_ids<<{ :server_id => local_record[:recordId], :internal_id => local_record[:id] } # to speed up deletion
			end

			# difference to find record to be deleted
			to_be_removed_server_record_ids = local_server_record_ids - @remote_server_record_ids

			# if there is a difference => remove
			if to_be_removed_server_record_ids.length > 0
				# get the array of internal record ids for removal
				to_be_removed_internal_record_ids = []
				to_be_removed_server_record_ids.each do |server_id_to_be_removed|
					# find the internal id using server id and parallel hash structure
					local_internal_record_ids.each do |element|
						if element[:server_id] == server_id_to_be_removed
							to_be_removed_internal_record_ids<<element[:internal_id]
						end
					end
				end

				# delete using array of ids
				Ground.delete( to_be_removed_internal_record_ids )

				# log
				puts '> removed ground with internal ids ' + to_be_removed_internal_record_ids.to_s
			end
		end
    end
end
