require_relative 'test_helper'

class ModelsLeitnerBoxTest < Minitest::Test
  def setup
    super
    @user = User.create!(telegram_id: 10, username: 'u10')
    @user.ensure_leitner_boxes
  end

  def test_repeat_period_unique_per_user
    period = @user.leitner_boxes.first.repeat_period
    dup = LeitnerBox.new(user: @user, repeat_period: period)

    refute dup.valid?
    assert_includes dup.errors[:repeat_period], 'has already been taken'
  end

  def test_next_box_returns_next_by_repeat_period
    boxes = @user.leitner_boxes.order(:repeat_period).to_a
    first = boxes.first
    second = boxes[1]

    assert_equal second, first.next_box
  end

  def test_next_box_returns_nil_for_last_box
    last = @user.leitner_boxes.order(:repeat_period).last
    assert_nil last.next_box
  end

  def test_first_box_returns_lowest_repeat_period
    first = @user.leitner_boxes.order(:repeat_period).first
    assert_equal first, LeitnerBox.first_box(@user)
  end
end
