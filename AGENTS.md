# AGENTS

- This repo is a plain Ruby app (no Rails).
- Environment variables live in `.env`; see `.env.example`.
- Database is Postgres via `DATABASE_URL`.
- Migrations run with `bundle exec rake db:migrate`.
- Word packs import via `bundle exec rake import:words[pack_code,path]`.
