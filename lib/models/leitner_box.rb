class LeitnerBox < ActiveRecord::Base
  belongs_to :user
  has_many :user_words

  validates :repeat_period, presence: true, numericality: { only_integer: true, greater_than: 0 },
                            uniqueness: { scope: :user_id }

  DEFAULT_REPEAT_PERIODS = [1, 2, 4, 7, 15, 30].freeze

  def next_box
    user.leitner_boxes.where('repeat_period > ?', repeat_period).order(:repeat_period).first
  end

  def self.first_box(user)
    user.leitner_boxes.order(:repeat_period).first
  end
end
