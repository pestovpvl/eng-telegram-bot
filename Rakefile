require 'rake'
require_relative 'config/environment'
require_relative 'lib/active_record_migration_shim'
namespace :db do
  desc 'Run database migrations'
  task :migrate do
    ActiveRecord::Migration.verbose = true
    ActiveRecord::MigrationContext.new(
      File.expand_path('db/migrate', __dir__),
      ActiveRecord::SchemaMigration,
      ActiveRecord::InternalMetadata
    ).migrate
  end
end

namespace :import do
  desc 'Import words from CSV: rake import:words[pack_code,path]'
  task :words, [:pack_code, :path] do |_, args|
    require_relative 'lib/word_importer'
    unless args[:pack_code] && args[:path]
      abort 'Usage: rake import:words[pack_code,path/to.csv]'
    end

    WordImporter.new(args[:pack_code], args[:path]).import!
  end
end
