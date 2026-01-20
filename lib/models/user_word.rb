class UserWord < ActiveRecord::Base
  belongs_to :user
  belongs_to :word
  belongs_to :leitner_box

  validates :user_id, presence: true, uniqueness: { scope: :word_id }
  validates :word_id, :leitner_box_id, :show_count, presence: true
  validates :learned, inclusion: { in: [true, false] }

  def increment_show_count
    update!(show_count: show_count + 1)
  end

  def remember!
    next_box = leitner_box.next_box
    if next_box
      update!(leitner_box: next_box, last_reviewed_at: Time.now.utc)
    else
      update!(learned: true, last_reviewed_at: Time.now.utc)
    end
  end

  def forget!
    update!(leitner_box: LeitnerBox.first_box(user), last_reviewed_at: Time.now.utc)
  end
end
