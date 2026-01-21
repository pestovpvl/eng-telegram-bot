require_relative 'test_helper'

ENV['BOT_DISABLE_RUN'] = '1'
ENV['DATABASE_URL'] = ENV['TEST_DATABASE_URL']
ENV['TELEGRAM_TOKEN'] = '123456:abcdefghijklmnopqrstuvwxyzABCDEFGHI'

require_relative '../bot'

class BotAppFlowTest < Minitest::Test
  FakeApi = Struct.new(:messages, :edited) do
    def send_message(chat_id:, text:, **)
      messages << { chat_id: chat_id, text: text }
    end

    def edit_message_text(chat_id:, message_id:, text:, **)
      edited << { chat_id: chat_id, message_id: message_id, text: text }
    end

    def answer_callback_query(**); end
  end

  FakeBot = Struct.new(:api)
  FakeChat = Struct.new(:id)
  FakeMessage = Struct.new(:text, :chat, :message_id)
  FakeUser = Struct.new(:id, :username, :first_name, :last_name, :language_code)
  FakeCallback = Struct.new(:from, :data, :message, :id)

  def setup
    super
    @api = FakeApi.new([], [])
    @app = BotApp.new(FakeBot.new(@api))
    @user = User.create!(telegram_id: 50, username: 'u50')
    @user.ensure_leitner_boxes
    @pack = Pack.create!(code: 'top500', name: 'Top 500')
  end

  def seed_one_word
    word = Word.create!(pack: @pack, english: 'test', russian: 'тест', definition: 'определение')
    box = @user.leitner_boxes.order(:repeat_period).first
    UserWord.create!(user: @user, word: word, leitner_box: box, show_count: 0, learned: false)
    word
  end

  def test_send_next_card_sends_word
    word = seed_one_word
    @user.update!(current_pack: @pack)

    @app.send(:send_next_card, 1, @user)

    assert_includes @api.messages.last[:text], word.english
  end

  def test_reveal_answer_includes_definition
    word = seed_one_word
    @user.update!(current_pack: @pack)
    callback = FakeCallback.new(FakeUser.new(@user.telegram_id, nil, nil, nil, 'en'), 'reveal', FakeMessage.new('', FakeChat.new(1), 10), 'cb1')

    @app.send(:reveal_answer, callback, @user, word.id)

    assert_includes @api.edited.last[:text], 'Определение'
  end

  def test_mark_answer_creates_review_event
    word = seed_one_word
    callback = FakeCallback.new(FakeUser.new(@user.telegram_id, nil, nil, nil, 'en'), 'mark:correct', FakeMessage.new('', FakeChat.new(1), 10), 'cb2')

    @app.send(:mark_answer, callback, @user, "correct:#{word.id}")

    assert_equal 1, ReviewEvent.where(user: @user, word: word).count
  end
end
