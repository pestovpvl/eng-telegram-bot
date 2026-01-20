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
      errors = e.respond_to?(:record) && e.record.respond_to?(:errors) ? e.record.errors.full_messages.join(', ') : e.message
      warn "Failed to find or create pack with code '#{@pack_code}': #{errors}"
      raise
    end

    imported = 0
    updated = 0
    skipped = 0

    begin
      CSV.foreach(@csv_path, headers: false) do |row|
        next if row.compact.empty?

        english = row[2].to_s.strip
        russian = row[3].to_s.strip
        definition = row[4]&.to_s&.strip

        if english.empty? || russian.empty?
          skipped += 1
          next
        end

        word = Word.find_or_initialize_by(pack: pack, english: english)
        word.russian = russian
        word.definition = definition if definition && !definition.empty?

        if word.new_record?
          if word.save
            imported += 1
          else
            warn "Failed to save new word '#{english}' in pack '#{pack.code}': #{word.errors.full_messages.join(', ')}"
          end
        else
          if word.save
            updated += 1
          else
            warn "Failed to update word '#{english}' in pack '#{pack.code}': #{word.errors.full_messages.join(', ')}"
          end
        end
      end
    rescue CSV::MalformedCSVError, Encoding::InvalidByteSequenceError, ArgumentError => e
      warn "Error while parsing CSV file '#{@csv_path}': #{e.class} - #{e.message}"
      raise
    end

    puts "Imported: #{imported}, updated: #{updated}, skipped: #{skipped}"
  end
end
