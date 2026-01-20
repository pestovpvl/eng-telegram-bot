class Word < ActiveRecord::Base
  belongs_to :pack
  has_many :user_words, dependent: :destroy
  has_many :review_events, dependent: :destroy

  validates :english, presence: true
  validates :russian, presence: true
end
