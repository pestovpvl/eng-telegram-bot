class User < ActiveRecord::Base
  has_many :leitner_boxes, dependent: :destroy
  has_many :user_words, dependent: :destroy
  has_many :review_events, dependent: :destroy

  belongs_to :current_pack, class_name: 'Pack', optional: true
  belongs_to :current_word, class_name: 'Word', optional: true

  validates :telegram_id, presence: true, uniqueness: true
  validates :daily_goal, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 1000 }, allow_nil: true

  DEFAULT_DAILY_GOAL = 20

  def ensure_leitner_boxes
    return if leitner_boxes.exists?

    LeitnerBox::DEFAULT_REPEAT_PERIODS.each do |repeat_period|
      leitner_boxes.create!(repeat_period: repeat_period)
    end
  end

  def daily_goal_value
    daily_goal || DEFAULT_DAILY_GOAL
  end
end
