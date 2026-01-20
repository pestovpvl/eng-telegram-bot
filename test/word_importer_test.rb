require 'tempfile'
require_relative 'test_helper'
require_relative '../lib/word_importer'

class WordImporterTest < Minitest::Test
  def test_import_creates_pack_and_words
    csv = Tempfile.new(['words', '.csv'])
    csv.write("English,Russian,disrupt,нарушать,ломать порядок\n")
    csv.write("English,Russian,bickering,препирательства,споры\n")
    csv.close

    importer = WordImporter.new('top500', csv.path)
    importer.import!

    pack = Pack.find_by(code: 'top500')
    assert pack
    assert_equal 'top500', pack.name
    assert_equal 2, pack.words.count

    word = pack.words.find_by(english: 'disrupt')
    assert_equal 'нарушать', word.russian
    assert_equal 'ломать порядок', word.definition
  ensure
    csv.unlink
  end

  def test_import_updates_existing_word
    pack = Pack.create!(code: 'top500', name: 'Top 500')
    Word.create!(pack: pack, english: 'aspire', russian: 'старое')

    csv = Tempfile.new(['words', '.csv'])
    csv.write("English,Russian,aspire,стремиться,желать\n")
    csv.close

    importer = WordImporter.new('top500', csv.path)
    importer.import!

    word = pack.words.find_by(english: 'aspire')
    assert_equal 'стремиться', word.russian
    assert_equal 'желать', word.definition
  ensure
    csv.unlink
  end
end
