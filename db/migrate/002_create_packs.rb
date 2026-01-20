class CreatePacks < ActiveRecord::Migration[7.0]
  def change
    create_table :packs do |t|
      t.string :code, null: false
      t.string :name, null: false

      t.timestamps
    end

    add_index :packs, :code, unique: true
  end
end
