namespace :db do
  desc "Drop and recreate the database for your current environment (make sure you pick the right one!)" 
  task :recreate => :environment do
    database_name = ActiveRecord::Base.configurations[RAILS_ENV]["database"]
    ActiveRecord::Base.connection.execute("DROP DATABASE IF EXISTS #{database_name}")
    ActiveRecord::Base.connection.execute("CREATE DATABASE #{database_name}")
    ActiveRecord::Base.connection.reconnect!
    Rake::Task["db:migrate"].invoke
    print "Finished recreating database for the environment: #{RAILS_ENV}\n\n"
  end
end