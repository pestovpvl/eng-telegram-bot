class UserWord < ActiveRecord::Base
  belongs_to :user
  belongs_to :word
  belongs_to :leitner_box

  validates :user_id, uniqueness: { scope: :word_id }

  def increment_show_count
    self.show_count ||= 0
    self.show_count += 1
    save!
  end

  def remember!
    next_box = leitner_box.next_box
    if next_box
      update!(leitner_box: next_box, last_reviewed_at: Time.now)
    else
      update!(learned: true, last_reviewed_at: Time.now)
    end
  end

  def forget!
    update!(leitner_box: LeitnerBox.first_box(user), last_reviewed_at: Time.now)
  end
end
