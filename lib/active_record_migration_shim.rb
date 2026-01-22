require 'active_record'

# Standalone ActiveRecord does not always define create_table for these classes.
module ActiveRecordMigrationShim
  def self.ensure_create_table!(klass, fallback_table_name)
    return if klass.respond_to?(:create_table)

    klass.define_singleton_method(:create_table) do
      conn = ActiveRecord::Base.connection
      table = respond_to?(:table_name) ? table_name : fallback_table_name
      return if conn.table_exists?(table)

      conn.create_table(table, id: false) do |t|
        if table == 'schema_migrations'
          t.string :version, null: false
        else
          t.string :key, null: false
          t.string :value
          t.datetime :created_at, null: false
          t.datetime :updated_at, null: false
        end
      end

      if table == 'schema_migrations'
        conn.add_index table, :version, unique: true, name: 'index_schema_migrations_on_version'
      else
        conn.add_index table, :key, unique: true, name: 'index_ar_internal_metadata_on_key'
      end
    end
  end
end

ActiveRecordMigrationShim.ensure_create_table!(ActiveRecord::SchemaMigration, 'schema_migrations')
ActiveRecordMigrationShim.ensure_create_table!(ActiveRecord::InternalMetadata, 'ar_internal_metadata')
