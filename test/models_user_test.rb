require_relative 'test_helper'

class ModelsUserTest < Minitest::Test
  def test_ensure_leitner_boxes_creates_defaults
    user = User.create!(telegram_id: 1, username: 'u1')
    assert_equal 0, user.leitner_boxes.count

    user.ensure_leitner_boxes

    periods = user.leitner_boxes.order(:repeat_period).pluck(:repeat_period)
    assert_equal LeitnerBox::DEFAULT_REPEAT_PERIODS, periods
  end

  def test_telegram_id_unique
    User.create!(telegram_id: 2, username: 'u2')
    dup = User.new(telegram_id: 2, username: 'u3')

    refute dup.valid?
    refute_empty dup.errors[:telegram_id]
  end

  def test_daily_goal_bounds
    user = User.new(telegram_id: 3, username: 'u3', daily_goal: 0)
    refute user.valid?
    refute_empty user.errors[:daily_goal]

    user.daily_goal = User::MAX_DAILY_GOAL + 1
    refute user.valid?
    refute_empty user.errors[:daily_goal]
  end

  def test_destroy_user_cascades
    user = User.create!(telegram_id: 4, username: 'u4')
    user.ensure_leitner_boxes
    pack = Pack.create!(code: 'top500', name: 'Top 500')
    word = Word.create!(pack: pack, english: 'test', russian: 'тест')
    user_word = UserWord.create!(user: user, word: word, leitner_box: user.leitner_boxes.first, show_count: 0, learned: false)
    ReviewEvent.create!(user: user, word: word, success: true, viewed_at: Time.now.utc)

    user.destroy

    assert_nil User.find_by(id: user.id)
    assert_nil UserWord.find_by(id: user_word.id)
    assert_equal 0, ReviewEvent.where(user_id: user.id).count
    assert_equal 0, LeitnerBox.where(user_id: user.id).count
  end
end
