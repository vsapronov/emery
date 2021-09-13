require "test/unit/runner/junitxml"

require 'emery'

class TaggedUnionWrapperJson < Test::Unit::TestCase
  def test_serialize
    data = Jsoner.to_json(T.tagged_union({circle: Circle, square: Square}), {"circle": Circle.new(radius: 123)})
    assert_equal '{"circle":{"radius":123}}', data, "Should serialize tagged union type to wrapper object"
  end

  def test_deserialize
    data = Jsoner.from_json(T.tagged_union({circle: Circle, square: Square}), '{"circle":{"radius":123}}')
    T.check(T.tagged_union({circle: Circle, square: Square}), data)
    assert_equal ({"circle": Circle.new(radius: 123)}), data, "Should deserialize tagged union type from wrapper object"
  end

  def test_deserialize_fail
    assert_raise JsonerError do
      Jsoner.from_json(T.tagged_union({str: String, int: Integer}), '{"bool":true}')
    end
  end
end

class TaggedUnionDiscriminatorJson < Test::Unit::TestCase
  def test_serialize
    data = Jsoner.to_json(T.tagged_union({circle: Circle, square: Square}, "_type"), {"circle": Circle.new(radius: 123)})
    assert_equal '{"radius":123,"_type":"circle"}', data, "Should serialize tagged union to object with discriminator"
  end

  def test_deserialize
    data = Jsoner.from_json(T.tagged_union({circle: Circle, square: Square}, "_type"), '{"_type":"circle","radius":123}')
    T.check(T.tagged_union({str: String, int: Integer}), data)
    assert_equal ({"circle": Circle.new(radius: 123)}), data, "Should deserialize tagged union type from object with discriminator"
  end
end

class Circle
  include DataClass
  val :radius, Integer
end

class Square
  include DataClass
  val :side, Integer
end