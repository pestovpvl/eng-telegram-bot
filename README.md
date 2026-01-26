# Eng Telegram Bot

Telegram bot for learning English words with the Leitner spaced repetition system.

## Setup

PostgreSQL is required (interval arithmetic and random ordering rely on PostgreSQL syntax).

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

If you're running the app via Docker, run the same command inside the container:

```bash
docker compose exec app make import-all
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
- `OPENAI_TTS_MODEL` (default `tts-1`)
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

Run Postgres and the app (ensure `DATABASE_URL` and `TEST_DATABASE_URL` are set in `.env`):

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

### Docker word pack imports

If you keep the CSVs in `data/words/`, you can run these helper scripts:

```bash
bin/import_top500_docker.sh
bin/import_top1000_docker.sh
bin/import_top2000_docker.sh
bin/import_function_words_docker.sh
bin/import_content_words_docker.sh
```

Each script runs the matching `docker compose run --rm app bundle exec rake "import:words[...]"` command
inside the container.

To import all packs in one go via Docker:

```bash
docker compose exec app make import-all
```

To delete all words and progress (use with care):

```bash
make delete-all
```

Note: This project expects PostgreSQL (interval arithmetic and random ordering use PostgreSQL syntax).

If tests fail with "database does not exist", recreate the db volume so the init script runs:

```bash
docker compose down -v
docker compose up -d db
```
