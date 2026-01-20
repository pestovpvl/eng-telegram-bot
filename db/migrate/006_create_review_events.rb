class CreateReviewEvents < ActiveRecord::Migration[7.0]
  def change
    create_table :review_events do |t|
      t.references :user, null: false, foreign_key: true
      t.references :word, null: false, foreign_key: true
      t.boolean :success, null: false, default: false
      t.datetime :viewed_at, null: false

      t.timestamps
    end
  end
end
