require 'dotenv/load'
require 'active_record'
require 'logger'

ActiveRecord::Base.logger = Logger.new($stdout) if ENV['AR_LOG'] == '1'

database_url = ENV['DATABASE_URL'].to_s.strip
abort 'DATABASE_URL environment variable is not set.' if database_url.empty?

ActiveRecord::Base.establish_connection(database_url)

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'models'
