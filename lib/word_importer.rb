require 'csv'
require_relative '../config/environment'

class WordImporter
  def initialize(pack_code, csv_path)
    @pack_code = pack_code
    @csv_path = csv_path
  end

  def import!
    pack = Pack.find_or_create_by!(code: @pack_code) do |p|
      p.name = @pack_code
    end

    imported = 0
    updated = 0
    skipped = 0

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
        imported += 1 if word.save
      else
        updated += 1 if word.save
      end
    end

    puts "Imported: #{imported}, updated: #{updated}, skipped: #{skipped}"
  end
end
