require "date"

module Codecs
  module BuiltinTypeCodec
    def self.applicable?(type)
      [String, Float, Integer, TrueClass, FalseClass, NilClass].include? type
    end
    def self.deserialize(type, json_value)
      T.check(type, json_value)
    end
    def self.serialize(type, value)
      T.check(type, value)
    end
  end

  module UnknownCodec
    def self.applicable?(type)
      type.instance_of? T::UnknownType
    end
    def self.deserialize(type, json_value)
      json_value
    end
    def self.serialize(type, value)
      value
    end
  end

  module ArrayCodec
    def self.applicable?(type)
      type.instance_of? T::ArrayType
    end
    def self.deserialize(type, json_value)
      T.check_not_nil(type, json_value)
      if !json_value.is_a?(Array)
        raise JsonerError.new("JSON value type #{json_value.class} is not Array")
      end
      json_value.map { |item_json_value| Jsoner.deserialize(type.item_type, item_json_value) }
    end
    def self.serialize(type, value)
      if !value.is_a?(Array)
        raise JsonerError.new("Value type #{json_value.class} is not Array")
      end
      value.map { |item| Jsoner.serialize(type.item_type, item) }
    end
  end

  module HashCodec
    def self.applicable?(type)
      type.instance_of? T::HashType
    end
    def self.deserialize(type, json_value)
      T.check_not_nil(type, json_value)
      if type.key_type != String
        raise JsonerError.new("Hash key type #{type.key_type} is not supported for JSON (de)serialization - key should be String")
      end
      if !json_value.is_a?(Hash)
        raise JsonerError.new("JSON value type #{json_value.class} is not Hash")
      end
      json_value.map do |key, value|
        [T.check(type.key_type, key), Jsoner.deserialize(type.value_type, value)]
      end.to_h
    end
    def self.serialize(type, value)
      if type.key_type != String
        raise JsonerError.new("Hash key type #{type.key_type} is not supported for JSON (de)serialization - key should be String")
      end
      if !value.is_a?(Hash)
        raise JsonerError.new("Value type #{value.class} is not Hash")
      end
      value.map do |key, value|
        [T.check(type.key_type, key), Jsoner.serialize(type.value_type, value)]
      end.to_h
    end
  end

  module UnionCodec
    def self.applicable?(type)
      type.instance_of? T::UnionType
    end
    def self.deserialize(type, json_value)
      type.types.each do |t|
        begin
          return Jsoner.deserialize(t, json_value)
        rescue JsonerError
        end
      end
      raise JsonerError.new("Value '#{json_value.inspect.to_s}' can not be deserialized as any of #{type.types.map { |t| t.to_s}.join(', ')}")
    end
    def self.serialize(type, value)
      T.check(type, value)
      t = type.types.find {|t| T.instance_of?(t, value) }
      Jsoner.serialize(t, value)
    end
  end

  module NilableCodec
    def self.applicable?(type)
      type.instance_of? T::NilableType
    end
    def self.deserialize(type, json_value)
      if json_value != nil
        Jsoner.deserialize(type.inner_type, json_value)
      else
        nil
      end
    end
    def self.serialize(type, value)
      if value != nil
        Jsoner.serialize(type.inner_type, value)
      else
        nil
      end
    end
  end

  module StringFormattedCodec
    def self.applicable?(type)
      type.instance_of? T::StringFormattedType
    end
    def self.deserialize(type, json_value)
      T.check(type, json_value)
    end
    def self.serialize(type, value)
      T.check(type, value)
    end
  end

  module FloatCodec
    def self.applicable?(type)
      type == Float
    end
    def self.deserialize(type, json_value)
      T.check(T.union(Float, Integer), json_value)
      json_value.to_f
    end
    def self.serialize(type, value)
      T.check(Float, value)
    end
  end

  module DateTimeCodec
    def self.applicable?(type)
      type == DateTime
    end
    def self.deserialize(type, json_value)
      T.check(String, json_value)
      begin
        DateTime.strptime(json_value, '%Y-%m-%dT%H:%M:%S')
      rescue
        raise JsonerError.new("Failed to parse DateTime from '#{json_value.inspect.to_s}' format %Y-%m-%dT%H:%M:%S is required")
      end
    end
    def self.serialize(type, value)
      T.check(DateTime, value)
      value.strftime('%Y-%m-%dT%H:%M:%S')
    end
  end

  module DateCodec
    def self.applicable?(type)
      type == Date
    end
    def self.deserialize(type, json_value)
      T.check(String, json_value)
      begin
        Date.strptime(json_value, '%Y-%m-%d')
      rescue
        raise JsonerError.new("Failed to parse Date from '#{json_value.inspect.to_s}' format %Y-%m-%d is required")
      end
    end
    def self.serialize(type, value)
      T.check(Date, value)
      value.strftime('%Y-%m-%d')
    end
  end

  module EnumCodec
    def self.applicable?(type)
      type.respond_to? :ancestors and type.ancestors.include? Enum
    end
    def self.deserialize(type, json_value)
      T.check(type, json_value)
    end

    def self.serialize(type, value)
      T.check(type, value)
    end
  end

  module DataClassCodec
    def self.applicable?(type)
      type.respond_to? :ancestors and type.ancestors.include? DataClass
    end
    def self.deserialize(type, json_value)
      T.check(T.hash(String, NilableUnknown), json_value)
      parameters = type.typed_attributes.map do |attr, attr_type|
        attr_value = json_value[attr.to_s]
        [attr, Jsoner.deserialize(attr_type, attr_value)]
      end
      return type.new(parameters.to_h)
    end

    def self.serialize(type, value)
      T.check(type, value)
      attrs = type.typed_attributes.map do |attr, attr_type|
        [attr, Jsoner.serialize(attr_type, value.send(attr))]
      end
      return attrs.to_h
    end
  end

  module TaggedUnionCodec
    def self.applicable?(type)
      type.respond_to? :ancestors and type.ancestors.include? TaggedUnion
    end
    def self.deserialize(type, json_value)
      if !json_value.is_a?(Hash)
        raise JsonerError.new("JSON value type #{json_value.class} is not Hash but it has to be Hash to represent a union")
      end
      if type.discriminator == nil
        if json_value.keys.length != 1
          raise JsonerError.new("JSON value #{json_value} should have only one key to represent union type wrapper object, found #{json_value.keys.length}")
        end
        tag_key = json_value.keys[0]
        if not type.typed_tags.key? tag_key.to_sym
          raise JsonerError.new("JSON key '#{tag_key}' does not match any tag in union type #{self}")
        end
        tag_type = type.typed_tags[tag_key.to_sym]
        tag_json_value = json_value[tag_key]
        tag_value = Jsoner.deserialize(tag_type, tag_json_value)
        return type.new({tag_key.to_sym => tag_value})
      else
        if not json_value.key? type.discriminator
          raise JsonerError.new("JSON value #{json_value} does not have discriminator field #{type.discriminator}")
        end
        tag_key = json_value[type.discriminator]
        tag_type = type.typed_tags[tag_key.to_sym]
        tag_value = Jsoner.deserialize(tag_type, json_value)
        return type.new({tag_key.to_sym => tag_value})
      end
    end
    def self.serialize(type, value)
      T.check(type, value)
      tag_key = value.current_tag
      tag_type = type.typed_tags[tag_key]
      tag_json_value = Jsoner.serialize(tag_type, value.send(tag_key))
      if type.discriminator == nil
        return { tag_key => tag_json_value }
      else
        tag_json_value[type.discriminator] = tag_key
        return tag_json_value
      end
    end
  end
end