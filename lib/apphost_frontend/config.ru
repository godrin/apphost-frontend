configFile=File.expand_path("../config.rb",__FILE__)
if File.exists?(configFile)
  require configFile
else
  HOSTNAME = "localhost"
  GITOLITE_ADMIN_HOME="/home/david/server/gitolite-admin"
end
require './app.rb'

run GitoliteAdminApp
