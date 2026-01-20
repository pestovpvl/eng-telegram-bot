require_relative 'test_helper'

class ModelsUserTest < Minitest::Test
  def test_ensure_leitner_boxes_creates_defaults
    user = User.create!(telegram_id: 1, username: 'u1')
    assert_equal 0, user.leitner_boxes.count

    user.ensure_leitner_boxes

    periods = user.leitner_boxes.order(:repeat_period).pluck(:repeat_period)
    assert_equal LeitnerBox::DEFAULT_REPEAT_PERIODS, periods
  end
end
