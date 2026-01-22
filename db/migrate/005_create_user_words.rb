class CreateUserWords < ActiveRecord::Migration[7.1]
  def change
    create_table :user_words do |t|
      t.references :user, null: false, foreign_key: true
      t.references :word, null: false, foreign_key: true
      t.references :leitner_box, null: false, foreign_key: true
      t.datetime :last_reviewed_at
      t.boolean :learned, null: false, default: false
      t.integer :show_count, null: false, default: 0

      t.timestamps
    end

    add_index :user_words, [:user_id, :word_id], unique: true
    add_index :user_words, [:last_reviewed_at, :learned]
  end
end
