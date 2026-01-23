class UserWord < ActiveRecord::Base
  belongs_to :user
  belongs_to :word
  belongs_to :leitner_box

  before_validation :ensure_defaults

  validates :user_id, presence: true, uniqueness: { scope: :word_id }
  validates :word_id, :leitner_box_id, :show_count, presence: true
  validates :show_count, numericality: { greater_than_or_equal_to: 0 }
  validates :learned, inclusion: { in: [true, false] }

  def increment_show_count
    update!(show_count: show_count + 1)
  end

  def remember!(reviewed_at = nil)
    reviewed_at ||= Time.now.utc
    ensure_defaults
    next_box = leitner_box.next_box
    if next_box
      update!(leitner_box: next_box, last_reviewed_at: reviewed_at, learned: false)
    else
      update!(learned: true, last_reviewed_at: reviewed_at)
    end
  end

  def forget!(reviewed_at = nil)
    reviewed_at ||= Time.now.utc
    ensure_defaults
    update!(leitner_box: LeitnerBox.first_box(user), last_reviewed_at: reviewed_at, learned: false)
  end

  private

  def ensure_defaults
    self.show_count = 0 if show_count.nil?
    self.learned = false if learned.nil?
  end
end
