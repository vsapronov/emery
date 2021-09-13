require "test/unit/runner/junitxml"

require "emery"

class TaggedUnionTypeEquality < Test::Unit::TestCase
  def test_equals
    assert_true Shape == Shape
  end

  def test_not_equals
    assert_false Shape == SmoothShape
  end
end

class TaggedUnionTags < Test::Unit::TestCase
  def test_tags_meta
    assert_equal ({:circle => Circle, :square => Square}), Shape.typed_tags, "Tags with types should be available on tagged union"
  end

  def test_read_tag
    u = Shape.new(circle: Circle.new(radius: 123))
    assert_equal :circle, u.current_tag, "Current tag should be readable"
    assert_equal Circle.new(radius: 123), u.current_value, "Current value should be readable"
    assert_equal Circle.new(radius: 123), u.circle, "Current union tag should allow to read it's data"
    assert_equal nil, u.square, "Non current tag should be nil"
  end

  def test_set_more_then_one_tag
    assert_raise ArgumentError do
      Shape.new(circle: Circle.new(radius: 123), square: Square.new(side: 123))
    end
  end
end

class TypeCheckTaggedUnion < Test::Unit::TestCase
  def test_success
    assert_equal(Shape.new(circle: Circle.new(radius: 123)), T.check(Shape, Shape.new(circle: Circle.new(radius: 123))))
  end

  def test_fail
    assert_raise TypeError do
      T.check(Shape, 123)
    end
  end
end

class TaggedUnionJson < Test::Unit::TestCase
  def test_serialize_wrapper
    data = Jsoner.to_json(Shape, Shape.new(circle: Circle.new(radius: 123)))
    assert_equal '{"circle":{"radius":123}}', data, "Should serialize tagged union type to wrapper object"
  end

  def test_deserialize_wrapper
    data = Jsoner.from_json(Shape, '{"circle":{"radius":123}}')
    T.check(Shape, data)
    assert_equal Shape.new(circle: Circle.new(radius: 123)), data, "Should deserialize tagged union type from wrapper object"
  end

  def test_deserialize_wrapper_fail
    assert_raise JsonerError do
      Jsoner.from_json(Shape, '{"non_exisiting":{"radius":123}}')
    end
  end

  def test_serialize_discriminator
    data = Jsoner.to_json(SmoothShape, SmoothShape.new(circle: Circle.new(radius: 123)))
    assert_equal '{"radius":123,"_type":"circle"}', data, "Should serialize tagged union to object with discriminator"
  end

  def test_deserialize_discriminator
    data = Jsoner.from_json(SmoothShape, '{"_type":"circle","radius":123}')
    T.check(SmoothShape, data)
    assert_equal SmoothShape.new(circle: Circle.new(radius: 123)), data, "Should deserialize tagged union type from object with discriminator"
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

class Shape
  include TaggedUnion
  tag :circle, Circle
  tag :square, Square
end

class Oval
  include DataClass
  val :height, Integer
  val :width, Integer
end

class SmoothShape
  include TaggedUnion
  with_discriminator "_type"
  tag :circle, Circle
  tag :oval, Oval
end
