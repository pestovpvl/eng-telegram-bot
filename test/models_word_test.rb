require_relative 'test_helper'

class ModelsWordTest < Minitest::Test
  def setup
    super
    @pack = Pack.create!(code: 'top500', name: 'Top 500')
  end

  def test_requires_english_and_russian
    word = Word.new(pack: @pack)
    refute word.valid?
    assert_includes word.errors[:english], "can't be blank"
    assert_includes word.errors[:russian], "can't be blank"
  end

  def test_english_unique_within_pack
    Word.create!(pack: @pack, english: 'test', russian: 'тест')
    dup = Word.new(pack: @pack, english: 'test', russian: 'дубль')

    refute dup.valid?
    assert_includes dup.errors[:english], 'has already been taken'
  end
end
