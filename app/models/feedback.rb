class Feedback < ActiveRecord::Base
  attr_accessible :description

	# post a feedback to salesforce | https://<instance_url>/services/apexrest/kio/v1.0/newFeedback
  	def self.post_feedbacks_batch_to_salesforce

  	# get batch from db
  	local_feedback_batch = self.all

    if local_feedback_batch.count > 0

    	# prepare structure
    	batch_for_salesforce = {
    		:reportList => local_feedback_batch
    	}

    	# convert rails style to json
    	batch_for_salesforce = batch_for_salesforce.to_json

    	# prepare call
    	endpoint = '/kio/v1.0/newFeedback'
    	url      = @@client.instance_url + '/services/apexrest' + endpoint

      begin
    	 # send batch
        result = @@client.http_post( url , data = batch_for_salesforce)

        # log
        puts '> post feedback call result: ' + result.body

        # if successfull delete the batch from the db
        if result.body == '"Success"' # NOTE salesforce is returning not Success but "Success"
          # success => remove the submitted records from local db
          Report.destroy( local_feedback_batch )
          puts '> successfully sent feedbacks to salesforce. deleted records from heroku db'
        else
          puts '>>> salesforce responded without success sending feedbacks to it. records are kept in the db for the next try [result and result.body]'
          puts result.body
          puts '<<<'
        end

      rescue Databasedotcom::SalesForceError => e
        puts '> salesforce exception error submitting feedbacks to salesforce: ' + e.message
      end
    else
      puts '> no feedbacks to send to salesforce'
    end
  end
end

