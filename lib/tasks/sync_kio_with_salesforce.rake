desc "This task syncs the app with salesforce every 10 mins (as per heroku scheduler setting)"
task :sync_kio_with_salesforce => :environment do

	# get news
	News.get_news_from_salesforce
	# get grounds
	Ground.get_grounds_from_salesforce
	# send reports
	Report.post_reports_batch_to_salesforce
	# send feedbacks
	Feedback.post_feedbacks_batch_to_salesforce
end
