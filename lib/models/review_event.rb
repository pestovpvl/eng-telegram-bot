class ReviewEvent < ActiveRecord::Base
  belongs_to :user
  belongs_to :word

  validates :success, inclusion: { in: [true, false] }
  validates :viewed_at, presence: true
end
