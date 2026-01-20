# Eng Telegram Bot

Telegram bot for learning English words with the Leitner spaced repetition system.

## Setup

1. Install gems:

```bash
bundle install
```

2. Configure `.env` based on `.env.example`.

3. Run migrations:

```bash
bundle exec rake db:migrate
```

4. Put CSV files into `data/words/` (recommended), then import (CSV format: lang_from, lang_to, english, russian, [definition]):

```bash
bundle exec rake import:words[top500,data/words/top500.csv]
```

Example packs you can import:

```bash
bundle exec rake import:words[top1000,data/words/top1000.csv]
bundle exec rake import:words[top2000,data/words/top2000.csv]
bundle exec rake import:words[function,data/words/function_words.csv]
bundle exec rake import:words[content,data/words/content_words.csv]
```

You can also import everything in `data/words/` at once:

```bash
make import-all
```

5. Start the bot:

```bash
bundle exec ruby bot.rb
```

## Project structure (recommended)

- `data/words/` — CSV word lists (ignored by git)
- `storage/audio/` — generated audio files (ignored by git)

## Audio generation (CSV -> MP3)

Use `bin/generate_audio_from_csv.rb` to create MP3 files for English words in column 3.

Environment variables:
- `OPENAI_API_KEY` (required)
- `OPENAI_TTS_URL` (optional, default OpenAI TTS endpoint)
- `OPENAI_TTS_MODEL` (default `gpt-4o-mini-tts`)
- `OPENAI_TTS_VOICE` (default `alloy`)
- `AUDIO_OUTPUT_DIR` (default `storage/audio`)

Example:

```bash
OPENAI_API_KEY=... bin/generate_audio_from_csv.rb /path/to/top500.csv
```


## Bot commands

- `/pack` — select a word pack
- `/learn` — start review
- `/goal 20` — set daily goal
- `/stats` — daily stats
- `/progress` — progress bar for today

## Tests

Run all tests (requires `TEST_DATABASE_URL` pointing to Postgres):

```bash
bundle exec ruby -Itest test/*_test.rb
```

## Docker

Run Postgres and the app:

```bash
docker compose up --build
```

Run migrations inside the container:

```bash
docker compose run --rm app bundle exec rake db:migrate
```

Run tests inside the container:

```bash
docker compose run --rm app bundle exec ruby -Itest test/*_test.rb
```

If tests fail with "database does not exist", recreate the db volume so the init script runs:

```bash
docker compose down -v
docker compose up -d db
```
