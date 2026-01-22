class UserWord < ActiveRecord::Base
  belongs_to :user
  belongs_to :word
  belongs_to :leitner_box

  validates :user_id, presence: true, uniqueness: { scope: :word_id }
  validates :word_id, :leitner_box_id, :show_count, presence: true
  validates :show_count, numericality: { greater_than_or_equal_to: 0 }
  validates :learned, presence: true, inclusion: { in: [true, false] }

  def increment_show_count
    update!(show_count: show_count + 1)
  end

  def remember!(reviewed_at = nil)
    reviewed_at ||= Time.now.utc
    next_box = leitner_box.next_box
    if next_box
      update!(leitner_box: next_box, last_reviewed_at: reviewed_at)
    else
      update!(learned: true, last_reviewed_at: reviewed_at)
    end
  end

  def forget!(reviewed_at = nil)
    reviewed_at ||= Time.now.utc
    update!(leitner_box: LeitnerBox.first_box(user), last_reviewed_at: reviewed_at)
  end
end
