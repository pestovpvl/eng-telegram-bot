#!/usr/bin/env ruby
require 'dotenv/load'
require 'telegram/bot'
require_relative 'config/environment'

TOKEN = ENV['TELEGRAM_TOKEN']
abort 'Set TELEGRAM_TOKEN in .env' if TOKEN.to_s.strip.empty?
abort 'Invalid TELEGRAM_TOKEN format' unless TOKEN =~ /\A\d+:[A-Za-z0-9_-]{35}\z/
PROXY = ENV['TG_PROXY']

class BotApp
  PROGRESS_BAR_WIDTH = 10
  MAX_DAILY_GOAL = 1000

  def initialize(bot)
    @bot = bot
  end

  def run
    ensure_default_packs

    @bot.listen do |message|
      case message
      when Telegram::Bot::Types::Message
        handle_message(message)
      when Telegram::Bot::Types::CallbackQuery
        handle_callback(message)
      end
    end
  end

  private

  def handle_message(message)
    text = message.text.to_s.strip
    return if text.empty?

    user = find_or_create_user(message.from)
    user.ensure_leitner_boxes

    if text.start_with?('/start')
      send_welcome(message, user)
    elsif text.start_with?('/pack')
      send_pack_selection(message, user)
    elsif text.start_with?('/goal')
      handle_goal(message, user)
    elsif text.start_with?('/stats')
      send_stats(message, user)
    elsif text.start_with?('/progress')
      send_progress(message, user)
    elsif text.start_with?('/learn')
      send_next_card(message.chat.id, user)
    else
      send_help(message.chat.id)
    end
  rescue StandardError => e
    warn "Error in handle_message: #{e.class}: #{e.message}"
    @bot.api.send_message(chat_id: message.chat.id, text: 'Произошла ошибка. Попробуйте позже.')
  end

  def handle_callback(query)
    user = find_or_create_user(query.from)
    user.ensure_leitner_boxes

    action, payload = query.data.to_s.split(':', 2)

    case action
    when 'pack'
      pack = Pack.find_by(id: payload.to_i)
      if pack
        user.update!(current_pack: pack)
        answer_callback(query, "Пакет выбран: #{pack.name}")
        send_next_card(query.message.chat.id, user)
      else
        answer_callback(query, 'Пакет не найден')
      end
    when 'reveal'
      reveal_answer(query, user, payload.to_i)
    when 'mark'
      mark_answer(query, user, payload)
    else
      answer_callback(query, 'Неизвестное действие')
    end
  rescue StandardError => e
    warn "Error in handle_callback: #{e.class}: #{e.message}"
    if query&.message
      @bot.api.send_message(chat_id: query.message.chat.id, text: 'Произошла ошибка. Попробуйте позже.')
    end
  end

  def send_welcome(message, user)
    text = "Привет! Я помогу учить слова по методу Лейтнера.\n\n" \
           "Команды:\n" \
           "/pack — выбрать набор слов\n" \
           "/learn — начать повторение\n" \
           "/goal 20 — дневная цель\n" \
           "/stats — статистика за сегодня\n" \
           "/progress — прогресс за сегодня"

    @bot.api.send_message(chat_id: message.chat.id, text: text)
    send_pack_selection(message, user)
  end

  def send_help(chat_id)
    text = "Я тебя не понял. Доступные команды: /pack, /learn, /goal, /stats, /progress"
    @bot.api.send_message(chat_id: chat_id, text: text)
  end

  def send_pack_selection(message, user)
    packs = Pack.order(:id).to_a
    if packs.empty?
      @bot.api.send_message(chat_id: message.chat.id, text: 'Пакеты не найдены. Попроси администратора добавить наборы слов и попробуй ещё раз позже.')
      return
    end

    buttons = packs.map do |pack|
      Telegram::Bot::Types::InlineKeyboardButton.new(
        text: pack.name,
        callback_data: "pack:#{pack.id}"
      )
    end

    markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: buttons.each_slice(2).to_a)
    @bot.api.send_message(chat_id: message.chat.id, text: 'Выбери набор слов:', reply_markup: markup)
  end

  def handle_goal(message, user)
    parts = message.text.to_s.strip.split
    if parts.length == 2 && parts[1].to_i > 0
      goal = [parts[1].to_i, MAX_DAILY_GOAL].min
      user.update!(daily_goal: goal)
      @bot.api.send_message(chat_id: message.chat.id, text: "Цель установлена: #{user.daily_goal_value} слов в день")
    else
      @bot.api.send_message(chat_id: message.chat.id, text: "Текущая цель: #{user.daily_goal_value}. Используй /goal 20")
    end
  end

  def send_stats(message, user)
    stats = today_stats(user)
    text = "Сегодня: #{stats[:total]} карточек\n" \
           "Правильно: #{stats[:correct]}\n" \
           "Неправильно: #{stats[:wrong]}\n" \
           "Цель: #{user.daily_goal_value}"

    @bot.api.send_message(chat_id: message.chat.id, text: text)
  end

  def send_progress(message, user)
    text = progress_line(user)
    @bot.api.send_message(chat_id: message.chat.id, text: text)
  end

  def send_next_card(chat_id, user)
    pack = user.current_pack || Pack.order(:id).first
    unless pack
      @bot.api.send_message(chat_id: chat_id, text: 'Сначала выбери набор /pack')
      return
    end

    word, user_word = next_word_for(user, pack)
    unless word
      @bot.api.send_message(chat_id: chat_id, text: 'Нет слов для изучения в этом наборе. Попроси администратора добавить слова и попробуй ещё раз позже.')
      return
    end

    user.update!(current_word: word)
    user_word.increment_show_count

    progress = progress_line(user)
    text = "#{progress}\n\n" \
           "Слово: #{word.english}"

    markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(
      inline_keyboard: [[
        Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Показать ответ', callback_data: "reveal:#{word.id}")
      ]]
    )

    @bot.api.send_message(chat_id: chat_id, text: text, reply_markup: markup)
  end

  def reveal_answer(query, user, word_id)
    word = Word.find_by(id: word_id)
    return answer_callback(query, 'Слово не найдено') unless word

    translation_line = "Ответ: #{word.russian}"
    definition_line = word.definition.to_s.strip.empty? ? nil : "\nОпределение: #{word.definition}"
    progress = progress_line(user)

    text = "#{progress}\n\n" \
           "Слово: #{word.english}\n" \
           "#{translation_line}#{definition_line}"

    markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(
      inline_keyboard: [[
        Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Правильно', callback_data: "mark:correct:#{word.id}"),
        Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Неправильно', callback_data: "mark:wrong:#{word.id}")
      ]]
    )

    @bot.api.edit_message_text(chat_id: query.message.chat.id, message_id: query.message.message_id, text: text, reply_markup: markup)
    answer_callback(query)
  end

  def mark_answer(query, user, payload)
    result, word_id = payload.split(':', 2)
    word = Word.find_by(id: word_id.to_i)
    return answer_callback(query, 'Слово не найдено') unless word

    begin
      user_word = UserWord.find_or_create_by!(user: user, word: word) do |uw|
        uw.leitner_box = LeitnerBox.first_box(user)
      end
    rescue ActiveRecord::RecordInvalid
      return answer_callback(query, 'Не удалось сохранить прогресс, попробуйте ещё раз')
    end

    success = result == 'correct'
    success ? user_word.remember! : user_word.forget!
    ReviewEvent.create!(user: user, word: word, success: success, viewed_at: Time.now.utc)

    answer_callback(query, success ? 'Отмечено как правильно' : 'Отмечено как неправильно')
    send_next_card(query.message.chat.id, user)
  end

  def next_word_for(user, pack)
    user.ensure_leitner_boxes

    now = Time.now.utc
    unless ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'
      raise "Unsupported database adapter: #{ActiveRecord::Base.connection.adapter_name}. This bot currently supports only PostgreSQL. Please migrate to PostgreSQL and see the README."
    end

    due = user.user_words
      .joins(:word, :leitner_box)
      .where(words: { pack_id: pack.id })
      .where(learned: false)
      # NOTE: This uses PostgreSQL interval syntax and RANDOM().
      .where('user_words.last_reviewed_at IS NULL OR (? - user_words.last_reviewed_at) >= (leitner_boxes.repeat_period * interval \'1 day\')', now)

    if due.exists?
      user_word = due.order(Arel.sql('RANDOM()')).first
      return [user_word.word, user_word]
    end

    unseen = Word.where(pack: pack)
                 .where.not(id: user.user_words.select(:word_id))
                 .order(:id)
    if (new_word = unseen.first)
      user_word = UserWord.create!(user: user, word: new_word, leitner_box: LeitnerBox.first_box(user))
      return [new_word, user_word]
    end

    fallback = user.user_words.joins(:word).where(words: { pack_id: pack.id }, learned: false)
    return nil unless fallback.exists?

    user_word = fallback.order(Arel.sql('RANDOM()')).first
    [user_word.word, user_word]
  end

  def progress_line(user)
    stats = today_stats(user)
    goal = user.daily_goal_value.to_i
    return "Прогресс: #{stats[:total]}" if goal <= 0

    filled = [(stats[:total].to_f / goal * PROGRESS_BAR_WIDTH).round, PROGRESS_BAR_WIDTH].min
    bar = '█' * filled + '░' * (PROGRESS_BAR_WIDTH - filled)
    "Прогресс: #{stats[:total]}/#{goal} #{bar}"
  end

  def today_stats(user)
    start_time = Time.now.utc.to_date.to_time
    end_time = start_time + 86_400

    scope = user.review_events.where(viewed_at: start_time...end_time)
    counts = scope.group(:success).count
    total = counts.values.sum
    correct = counts[true] || 0
    {
      total: total,
      correct: correct,
      wrong: total - correct
    }
  end

  def answer_callback(query, text = nil)
    @bot.api.answer_callback_query(callback_query_id: query.id, text: text, show_alert: false)
  rescue Telegram::Bot::Exceptions::ResponseError, StandardError => e
    warn "Failed to answer callback query #{query.id}: #{e.class}: #{e.message}"
    nil
  end

  def find_or_create_user(from)
    user = User.find_or_initialize_by(telegram_id: from.id)
    user.username = from.username
    user.first_name = from.first_name
    user.last_name = from.last_name
    user.locale = from.language_code
    user.daily_goal ||= User::DEFAULT_DAILY_GOAL
    user.save!
    user
  end

  def ensure_default_packs
    return if Pack.exists?

    Pack.create!(code: 'top500', name: 'Top 500')
    Pack.create!(code: 'top1000', name: 'Top 1000')
    Pack.create!(code: 'top2000', name: 'Top 2000')
    Pack.create!(code: 'function', name: 'Function Words')
    Pack.create!(code: 'content', name: 'Content Words')
  end
end

Telegram::Bot::Client.run(TOKEN, proxy: PROXY) do |bot|
  BotApp.new(bot).run
end
