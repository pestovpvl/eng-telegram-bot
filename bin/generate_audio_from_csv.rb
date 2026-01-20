#!/usr/bin/env ruby
require 'csv'
require 'fileutils'
require 'faraday'
require 'json'
require 'dotenv/load'

API_KEY = ENV['OPENAI_API_KEY']
API_URL = ENV.fetch('OPENAI_TTS_URL', 'https://api.openai.com/v1/audio/speech')
MODEL = ENV.fetch('OPENAI_TTS_MODEL', 'gpt-4o-mini-tts')
VOICE = ENV.fetch('OPENAI_TTS_VOICE', 'alloy')
OUTPUT_DIR = ENV.fetch('AUDIO_OUTPUT_DIR', 'storage/audio')

abort 'Set OPENAI_API_KEY in .env' unless API_KEY

csv_path = ARGV[0]
abort 'Usage: bin/generate_audio_from_csv.rb path/to/words.csv' unless csv_path && File.exist?(csv_path)

voice_dir = File.join(OUTPUT_DIR, VOICE)
FileUtils.mkdir_p(voice_dir)

conn = Faraday.new do |f|
  f.options.timeout = 120
  f.adapter Faraday.default_adapter
end

rows = 0
saved = 0
skipped = 0

CSV.foreach(csv_path, headers: false) do |row|
  rows += 1
  english = row[2].to_s.strip
  next if english.empty?

  filename = english.downcase.gsub(/[^a-z0-9]+/, '_').gsub(/^_+|_+$/, '')
  filename = "word_#{rows}" if filename.empty?
  path = File.join(voice_dir, "#{filename}.mp3")

  if File.exist?(path)
    skipped += 1
    next
  end

  response = conn.post(API_URL) do |req|
    req.headers['Authorization'] = "Bearer #{API_KEY}"
    req.headers['Content-Type'] = 'application/json'
    req.body = {
      model: MODEL,
      voice: VOICE,
      input: english,
      format: 'mp3'
    }.to_json
  end

  unless response.success?
    warn "Failed for '#{english}': #{response.status} #{response.body}"
    next
  end

  File.binwrite(path, response.body)
  saved += 1
end

puts "Processed: #{rows}, saved: #{saved}, skipped: #{skipped}"
