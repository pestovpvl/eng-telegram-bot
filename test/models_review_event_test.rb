require_relative 'test_helper'

class ModelsReviewEventTest < Minitest::Test
  def setup
    super
    @user = User.create!(telegram_id: 20, username: 'u20')
    @pack = Pack.create!(code: 'top500', name: 'Top 500')
    @word = Word.create!(pack: @pack, english: 'test', russian: 'тест')
  end

  def test_associations
    event = ReviewEvent.create!(user: @user, word: @word, success: true, viewed_at: Time.now.utc)

    assert_equal @user, event.user
    assert_equal @word, event.word
  end
end
