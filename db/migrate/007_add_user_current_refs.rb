class AddUserCurrentRefs < ActiveRecord::Migration[7.1]
  def change
    add_foreign_key :users, :packs, column: :current_pack_id
    add_foreign_key :users, :words, column: :current_word_id
  end
end
