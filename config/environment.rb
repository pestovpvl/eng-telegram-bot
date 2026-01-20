require 'dotenv/load'
require 'active_record'
require 'logger'

ActiveRecord::Base.logger = Logger.new($stdout) if ENV['AR_LOG'] == '1'

ActiveRecord::Base.establish_connection(ENV.fetch('DATABASE_URL'))

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'models'
