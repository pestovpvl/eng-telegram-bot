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

    # NOTE: We read rows into memory so we can pre-load existing words for comparison.
    rows = []
    begin
      CSV.foreach(@csv_path, headers: false, encoding: 'UTF-8') { |row| rows << row }
    rescue CSV::MalformedCSVError,
           Encoding::InvalidByteSequenceError,
           ArgumentError,
           Errno::ENOENT,
           Errno::EACCES => e
      warn "Error while parsing CSV file '#{@csv_path}': #{e.class} - #{e.message}"
      raise
    end

    english_values = rows.filter_map do |row|
      next if row.compact.empty?

      next if row.length < 4

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

    # NOTE: This intentionally saves per-row (no bulk upsert) so we can report validation
    # errors with the exact offending row and word. For the currently expected CSV sizes
    # (small to medium teaching packs imported infrequently), the per-row overhead is
    # acceptable and keeps the implementation straightforward.
    #
    # If import volume or frequency grows significantly, consider switching to a bulk
    # insert/upsert strategy (e.g. insert_all / upsert_all or DB-specific bulk APIs),
    # but be aware that doing so will require a different, coarser-grained approach to
    # error reporting.
    rows.each do |row|
      next if row.compact.empty?

      if row.length < 4
        failed += 1
        warn "Row has insufficient columns for expected format (need at least 4 columns: 2 = english, 3 = russian, 4 = optional definition; got #{row.length}): #{row.inspect}"
        next
      end

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
      elsif word.changed?
        if word.save
          updated += 1
        else
          failed += 1
          warn "Failed to update word '#{english}' in pack '#{pack.code}': #{word.errors.full_messages.join(', ')}"
        end
      else
        skipped += 1
      end
    end

    puts "Imported: #{imported}, updated: #{updated}, skipped: #{skipped}, failed: #{failed}"
  end
end
