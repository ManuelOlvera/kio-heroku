##################################################################
# authenticate the databasedotcom client
##################################################################

puts "> authentication with username and password"

# generate client using heroku ENV vars and local export vars (see omniauth.rb) | :host when connecting to sandbox
# @@client = Databasedotcom::Client.new :client_id => "3MVG9_7ddP9KqTzcZNlY7gQI32.qDwVMzUggPsH_nI_f0CrSaCdOX6.48GNV5Kgt4Us12NrkcrNdg7p7M1RLv", :client_secret => "1074214033172658342", :host => "test.salesforce.com"
@@client = Databasedotcom::Client.new :client_id => "3MVG99qusVZJwhsmKYfJHWTxa2xhAW.C0ON_RldSy3BK77TkjMDZhxe2k4yAW5JcZ5ckltwCx.dHRpytpf3b6", :client_secret => "5921374081795068997", :host => "login.salesforce.com"

# authenticate directly with username and password+security token (not using oauth)
@@client.authenticate :username => "muser@kio.com", :password => "jFN0xtczh5nPRhQF0cWIf77Bgg5HaMMZa"


puts "> instance url " + @@client.instance_url

# get news
#News.get_news_from_salesforce

# get grounds
#Ground.get_grounds_from_salesforce
