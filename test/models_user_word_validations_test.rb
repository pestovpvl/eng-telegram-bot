require_relative 'test_helper'

class ModelsUserWordValidationsTest < Minitest::Test
  def setup
    super
    @user = User.create!(telegram_id: 30, username: 'u30')
    @user.ensure_leitner_boxes
    @pack = Pack.create!(code: 'top500', name: 'Top 500')
    @word = Word.create!(pack: @pack, english: 'test', russian: 'тест')
    @box = @user.leitner_boxes.first
  end

  def test_requires_foreign_keys_and_show_count
    user_word = UserWord.new
    refute user_word.valid?
    refute_empty user_word.errors[:user_id]
    refute_empty user_word.errors[:word_id]
    refute_empty user_word.errors[:leitner_box_id]
    refute_empty user_word.errors[:show_count]
  end

  def test_learned_inclusion
    user_word = UserWord.new(user: @user, word: @word, leitner_box: @box, show_count: 0)
    user_word.learned = nil
    refute user_word.valid?
    refute_empty user_word.errors[:learned]
  end
end
