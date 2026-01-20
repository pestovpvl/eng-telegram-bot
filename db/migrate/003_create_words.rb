class CreateWords < ActiveRecord::Migration[7.0]
  def change
    create_table :words do |t|
      t.references :pack, null: false, foreign_key: true
      t.string :english, null: false
      t.string :russian, null: false
      t.text :definition
      t.string :audio_path

      t.timestamps
    end

    add_index :words, [:pack_id, :english], unique: true
  end
end
