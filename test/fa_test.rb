require 'test_helper'

class FaTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Fa::VERSION
  end

  def test_equals
    a = Fa.compile("a")
    b = Fa.compile("b")
    ab = Fa.compile("ab")
    assert ab.equals(a.concat(b))
    assert !ab.equals(b.concat(a))
  end

  def test_contains
    a = Fa.compile("(a|b)*")
    s = Fa.compile("abaabbab")
    assert a.contains(s)
    assert !s.contains(a)
  end

  def test_is_basic
    basic = [ :empty, :epsilon, :total ]
    basic.each do |b|
      fa = Fa.make_basic(b)
      basic.each do |t|
        assert_equal (b == t), fa.is_basic(t)
      end
    end
  end

  def test_complement
    fa = Fa.make_basic(:empty).complement
    assert fa.total?
    fa = fa.complement
    assert fa.empty?
  end
end
