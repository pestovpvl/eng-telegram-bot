require_relative 'test_helper'

class ModelsPackTest < Minitest::Test
  def test_requires_code_and_name
    pack = Pack.new
    refute pack.valid?
    refute_empty pack.errors[:code]
    refute_empty pack.errors[:name]
  end

  def test_code_is_unique
    Pack.create!(code: 'top500', name: 'Top 500')
    dup = Pack.new(code: 'top500', name: 'Another')

    refute dup.valid?
    refute_empty dup.errors[:code]
  end

  def test_destroy_pack_cascades_words
    pack = Pack.create!(code: 'top500', name: 'Top 500')
    word = Word.create!(pack: pack, english: 'test', russian: 'тест')

    pack.destroy

    assert_nil Pack.find_by(id: pack.id)
    assert_nil Word.find_by(id: word.id)
  end
end
