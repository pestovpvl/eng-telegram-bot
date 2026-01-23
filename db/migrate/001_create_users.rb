class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.bigint :telegram_id, null: false
      t.string :username
      t.string :first_name
      t.string :last_name
      t.string :locale
      t.integer :daily_goal
      t.bigint :current_pack_id
      t.bigint :current_word_id

      t.timestamps
    end

    add_index :users, :telegram_id, unique: true
  end
end
