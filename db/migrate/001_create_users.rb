class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.bigint :telegram_id, null: false
      t.string :username
      t.string :first_name
      t.string :last_name
      t.string :locale
      t.integer :daily_goal
      t.references :current_pack, foreign_key: { to_table: :packs }, type: :bigint
      t.references :current_word, foreign_key: { to_table: :words }, type: :bigint

      t.timestamps
    end

    add_index :users, :telegram_id, unique: true
  end
end
