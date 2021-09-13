require "json"

class JsonerError < StandardError
end

module Jsoner
  @@serializers = [
      Serializers::FloatSerializer,
      Serializers::DateSerializer,
      Serializers::DateTimeSerializer,
      Serializers::StringFormattedSerializer,
      Serializers::UnionSerializer,
      Serializers::NilableSerializer,
      Serializers::ArraySerializer,
      Serializers::HashSerializer,
      Serializers::UnknownSerializer,
      Serializers::EnumSerializer,
      Serializers::DataClassSerializer,
      Serializers::TaggedUnionSerializer,
      Serializers::BuiltinTypeSerializer,
  ]

  def self.set_serializer(serializer)
    @@serializers.insert(0, serializer)
  end

  def Jsoner.find_serializer(type)
    @@serializers.each do |serializer|
      if serializer.applicable?(type)
        return serializer
      end
    end
    return nil
  end

  def Jsoner.from_json(type, json)
    data = JSON.parse(json)
    return deserialize(type, data)
  end

  def Jsoner.deserialize(type, json_value)
    begin
      serializer = Jsoner.find_serializer(type)
      if serializer == nil
        raise JsonerError.new("Type #{type} is not supported in Jsoner deserialization")
      end
      return serializer.deserialize(type, json_value)
    rescue StandardError => error
      raise JsonerError.new(error.message)
    end
  end

  def Jsoner.to_json(type, value)
    JSON.dump(serialize(type, value))
  end

  def Jsoner.serialize(type, value)
    begin
      serializer = Jsoner.find_serializer(type)
      if serializer == nil
        raise JsonerError.new("Type #{type} is not supported in Jsoner serialization")
      end
      return serializer.serialize(type, value)
    rescue StandardError => error
      raise JsonerError.new(error.message)
    end
  end
end