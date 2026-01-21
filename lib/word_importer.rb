require 'csv'
require_relative '../config/environment'

class WordImporter
  def initialize(pack_code, csv_path)
    @pack_code = pack_code
    @csv_path = csv_path
  end

  def import!
    begin
      pack = Pack.find_or_create_by!(code: @pack_code) do |p|
        p.name = @pack_code
      end
    rescue ActiveRecord::RecordInvalid => e
      warn "Failed to find or create pack with code '#{@pack_code}': #{e.message}"
      raise
    end

    imported = 0
    updated = 0
    skipped = 0
    failed = 0

    rows = []
    begin
      CSV.foreach(@csv_path, headers: false) { |row| rows << row }
    rescue CSV::MalformedCSVError, Encoding::InvalidByteSequenceError, ArgumentError => e
      warn "Error while parsing CSV file '#{@csv_path}': #{e.class} - #{e.message}"
      raise
    end

    english_values = rows.filter_map do |row|
      next if row.compact.empty?

      english = row[2].to_s.strip
      russian = row[3].to_s.strip
      next if english.empty? || russian.empty?

      english
    end

    existing_words = if english_values.empty?
                       {}
                     else
                       Word.where(pack: pack, english: english_values.uniq).index_by(&:english)
                     end

    # NOTE: This still saves per-row (no bulk upsert) to keep error reporting simple.
    rows.each do |row|
      next if row.compact.empty?

      english = row[2].to_s.strip
      russian = row[3].to_s.strip
      definition = row[4]&.to_s&.strip

      if english.empty? || russian.empty?
        skipped += 1
        next
      end

      word = existing_words[english] || Word.new(pack: pack, english: english)
      word.russian = russian
      word.definition = definition.nil? || definition.empty? ? nil : definition

      if word.new_record?
        if word.save
          imported += 1
        else
          failed += 1
          warn "Failed to save new word '#{english}' in pack '#{pack.code}': #{word.errors.full_messages.join(', ')}"
        end
      else
        if word.save
          updated += 1
        else
          failed += 1
          warn "Failed to update word '#{english}' in pack '#{pack.code}': #{word.errors.full_messages.join(', ')}"
        end
      end
    end

    puts "Imported: #{imported}, updated: #{updated}, skipped: #{skipped}, failed: #{failed}"
  end
end
