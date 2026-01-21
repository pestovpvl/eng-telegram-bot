require_relative 'test_helper'

ENV['BOT_DISABLE_RUN'] = '1'
ENV['DATABASE_URL'] = ENV['TEST_DATABASE_URL']
ENV['TELEGRAM_TOKEN'] = '123456:abcdefghijklmnopqrstuvwxyzABCDEFGHI'

require_relative '../bot'

class BotAppTest < Minitest::Test
  FakeApi = Struct.new(:messages) do
    def send_message(chat_id:, text:, **)
      messages << { chat_id: chat_id, text: text }
    end
    def answer_callback_query(**); end
    def edit_message_text(**); end
  end

  FakeBot = Struct.new(:api) do
    def listen; end
  end

  FakeChat = Struct.new(:id)
  FakeMessage = Struct.new(:text, :chat)

  def setup
    super
    @api = FakeApi.new([])
    @app = BotApp.new(FakeBot.new(@api))
    @user = User.create!(telegram_id: 40, username: 'u40', daily_goal: 5)
    @user.ensure_leitner_boxes
    @pack = Pack.create!(code: 'top500', name: 'Top 500')
  end

  def test_next_word_for_returns_due_word
    word = Word.create!(pack: @pack, english: 'test', russian: 'тест')
    box = @user.leitner_boxes.order(:repeat_period).first
    UserWord.create!(user: @user, word: word, leitner_box: box, show_count: 0, learned: false, last_reviewed_at: nil)

    chosen_word, _user_word = @app.send(:next_word_for, @user, @pack)
    assert_equal word, chosen_word
  end

  def test_progress_line_uses_daily_goal
    word = Word.create!(pack: @pack, english: 'test', russian: 'тест')
    ReviewEvent.create!(user: @user, word: word, success: true, viewed_at: Time.now.utc)
    ReviewEvent.create!(user: @user, word: word, success: false, viewed_at: Time.now.utc)

    line = @app.send(:progress_line, @user)
    assert_includes line, '2/5'
  end

  def test_handle_goal_caps_max
    message = FakeMessage.new('/goal 9999', FakeChat.new(1))

    @app.send(:handle_goal, message, @user)

    assert_equal User::MAX_DAILY_GOAL, @user.reload.daily_goal
    assert_includes @api.messages.last[:text], User::MAX_DAILY_GOAL.to_s
  end

  def test_handle_goal_invalid_input
    message = FakeMessage.new('/goal abc', FakeChat.new(1))

    @app.send(:handle_goal, message, @user)

    assert_includes @api.messages.last[:text], 'Некорректное значение цели'
  end
end
