require_relative 'test_helper'

class ModelsWordTest < Minitest::Test
  def setup
    super
    @pack = Pack.create!(code: 'top500', name: 'Top 500')
  end

  def test_requires_english_and_russian
    word = Word.new(pack: @pack)
    refute word.valid?
    refute_empty word.errors[:english]
    refute_empty word.errors[:russian]
  end

  def test_english_unique_within_pack
    Word.create!(pack: @pack, english: 'test', russian: 'тест')
    dup = Word.new(pack: @pack, english: 'test', russian: 'дубль')

    refute dup.valid?
    refute_empty dup.errors[:english]
  end
end
