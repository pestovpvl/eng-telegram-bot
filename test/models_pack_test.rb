require_relative 'test_helper'

class ModelsPackTest < Minitest::Test
  def test_requires_code_and_name
    pack = Pack.new
    refute pack.valid?
    assert_includes pack.errors[:code], "can't be blank"
    assert_includes pack.errors[:name], "can't be blank"
  end

  def test_code_is_unique
    Pack.create!(code: 'top500', name: 'Top 500')
    dup = Pack.new(code: 'top500', name: 'Another')

    refute dup.valid?
    assert_includes dup.errors[:code], 'has already been taken'
  end
end
