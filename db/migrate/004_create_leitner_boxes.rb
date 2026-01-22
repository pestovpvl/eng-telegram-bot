class CreateLeitnerBoxes < ActiveRecord::Migration[7.1]
  def change
    create_table :leitner_boxes do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :repeat_period, null: false

      t.timestamps
    end

    add_index :leitner_boxes, [:user_id, :repeat_period], unique: true
  end
end
