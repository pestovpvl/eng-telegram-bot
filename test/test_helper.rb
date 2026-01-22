require 'minitest/autorun'
require 'active_record'
require 'logger'
require_relative '../lib/active_record_migration_shim'

ActiveRecord::Base.logger = Logger.new($stdout) if ENV['AR_LOG'] == '1'

test_db_url = ENV['TEST_DATABASE_URL'].to_s.strip
abort 'TEST_DATABASE_URL is required for tests.' if test_db_url.empty?

ActiveRecord::Base.establish_connection(test_db_url)
migrations_path = File.expand_path('../db/migrate', __dir__)
ActiveRecord::Migration.verbose = false

ActiveRecord::SchemaMigration.create_table
ActiveRecord::InternalMetadata.create_table

ActiveRecord::MigrationContext.new(
  migrations_path,
  ActiveRecord::SchemaMigration,
  ActiveRecord::InternalMetadata
).migrate

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))
require 'models'

class Minitest::Test
  def setup
    ReviewEvent.delete_all
    UserWord.delete_all
    Word.delete_all
    LeitnerBox.delete_all
    Pack.delete_all
    User.delete_all
  end
end
