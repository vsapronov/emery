require "json"

class JsonerError < StandardError
end

module Jsoner
  @@codecs = [
    Codecs::FloatCodec,
    Codecs::DateCodec,
    Codecs::DateTimeCodec,
    Codecs::StringFormattedCodec,
    Codecs::UnionCodec,
    Codecs::NilableCodec,
    Codecs::ArrayCodec,
    Codecs::HashCodec,
    Codecs::UnknownCodec,
    Codecs::EnumCodec,
    Codecs::DataClassCodec,
    Codecs::TaggedUnionCodec,
    Codecs::BuiltinTypeCodec,
  ]

  def self.insert_codec(codec)
    @@codecs.insert(0, codec)
  end

  def Jsoner.find_codec(type)
    @@codecs.each do |serializer|
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
      codec = Jsoner.find_codec(type)
      if codec == nil
        raise JsonerError.new("Type #{type} is not supported in Jsoner deserialization")
      end
      return codec.deserialize(type, json_value)
    rescue StandardError => error
      raise JsonerError.new(error.message)
    end
  end

  def Jsoner.to_json(type, value)
    JSON.dump(serialize(type, value))
  end

  def Jsoner.serialize(type, value)
    begin
      codec = Jsoner.find_codec(type)
      if codec == nil
        raise JsonerError.new("Type #{type} is not supported in Jsoner serialization")
      end
      return codec.serialize(type, value)
    rescue StandardError => error
      raise JsonerError.new(error.message)
    end
  end
end