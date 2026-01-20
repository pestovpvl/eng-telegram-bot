class ReviewEvent < ActiveRecord::Base
  belongs_to :user
  belongs_to :word

  validates :success, :viewed_at, presence: true
end
