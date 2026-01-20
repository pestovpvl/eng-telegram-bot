require_relative 'test_helper'

class ModelsUserWordTest < Minitest::Test
  def setup
    super
    @user = User.create!(telegram_id: 2, username: 'u2')
    @user.ensure_leitner_boxes
    @pack = Pack.create!(code: 'top500', name: 'Top 500')
    @word = Word.create!(pack: @pack, english: 'test', russian: 'тест')
  end

  def test_remember_moves_to_next_box
    box1 = @user.leitner_boxes.order(:repeat_period).first
    box2 = @user.leitner_boxes.order(:repeat_period).second

    user_word = UserWord.create!(user: @user, word: @word, leitner_box: box1)
    user_word.remember!

    assert_equal box2.id, user_word.reload.leitner_box_id
    refute user_word.learned
    assert user_word.last_reviewed_at
  end

  def test_remember_sets_learned_when_last_box
    last_box = @user.leitner_boxes.order(:repeat_period).last
    user_word = UserWord.create!(user: @user, word: @word, leitner_box: last_box)

    user_word.remember!

    assert user_word.reload.learned
    assert user_word.last_reviewed_at
  end

  def test_forget_moves_to_first_box
    last_box = @user.leitner_boxes.order(:repeat_period).last
    first_box = @user.leitner_boxes.order(:repeat_period).first
    user_word = UserWord.create!(user: @user, word: @word, leitner_box: last_box)

    user_word.forget!

    assert_equal first_box.id, user_word.reload.leitner_box_id
    assert user_word.last_reviewed_at
  end
end
