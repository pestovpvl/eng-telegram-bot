require_relative 'test_helper'

class ModelsUserGoalTest < Minitest::Test
  def test_daily_goal_value_falls_back
    user = User.create!(telegram_id: 11, username: 'u11')
    assert_equal User::DEFAULT_DAILY_GOAL, user.daily_goal_value
  end

  def test_daily_goal_value_uses_custom
    user = User.create!(telegram_id: 12, username: 'u12', daily_goal: 42)
    assert_equal 42, user.daily_goal_value
  end
end
