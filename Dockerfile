FROM ruby:3.3-alpine

RUN apk add --no-cache build-base postgresql-dev tzdata

WORKDIR /app

COPY Gemfile Gemfile.lock* ./
RUN bundle install

COPY . .

CMD ["bundle", "exec", "ruby", "bot.rb"]
