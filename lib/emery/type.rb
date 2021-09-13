require 'emery/enum'

module T
  def T.check_not_nil(type, value)
    if value == nil
      raise TypeError.new("Type #{type.to_s} does not allow nil value")
    end
  end

  class UnknownType
    def to_s
      "Unknown"
    end
    def check(value)
      T.check_not_nil(self, value)
    end
  end

  class NilableType
    attr_reader :inner_type
    def initialize(inner_type)
      @inner_type = inner_type
    end
    def to_s
      "Nilable[#{inner_type.to_s}]"
    end
    def check(value)
      if value != nil
        T.check(inner_type, value)
      end
    end
    def ==(other)
      T.instance_of?(NilableType, other) and self.inner_type == other.inner_type
    end
  end

  class UnionType
    attr_reader :types
    def initialize(*types)
      @types = types
    end
    def to_s
      "Union[#{types.map { |t| t.to_s}.join(', ')}]"
    end
    def check(value)
      type = types.find {|t| T.instance_of?(t, value) }
      if type == nil
        raise TypeError.new("Value '#{value.inspect.to_s}' type is #{value.class} - any of #{@types.map { |t| t.to_s}.join(', ')} required")
      end
    end
    def ==(other)
      T.instance_of?(UnionType, other) and (self.types - other.types).empty?
    end
  end

  class TaggedUnionType
    attr_reader :cases
    attr_reader :discriminator
    def initialize(cases, discriminator = nil)
      @cases = cases
      @discriminator = discriminator
    end
    def to_s
      "TaggedUnion[#{cases.map { |k, t| "#{k}: #{t}"}.join(', ')}]"
    end
    def check(value)
      T.check_not_nil(self, value)
      if !value.is_a? Hash
        raise TypeError.new("Value '#{value.inspect.to_s}' type is #{value.class} - Hash is required for tagged union")
      end
    end
    def ==(other)
      return false
      #      T.instance_of?(TaggedUnionType, other) and (self.cases - other.cases).empty?
    end
  end

  class ArrayType
    attr_reader :item_type
    def initialize(item_type)
      @item_type = item_type
    end
    def to_s
      "Array[#{item_type.to_s}]"
    end
    def check(value)
      T.check_not_nil(self, value)
      if !value.is_a? Array
        raise TypeError.new("Value '#{value.inspect.to_s}' type is #{value.class} - Array is required")
      end
      value.each { |item_value| T.check(item_type, item_value) }
    end
    def ==(other)
      T.instance_of?(ArrayType, other) and self.item_type == other.item_type
    end
  end

  class HashType
    attr_reader :key_type
    attr_reader :value_type
    def initialize(key_type, value_type)
      @key_type = key_type
      @value_type = value_type
    end
    def to_s
      "Hash[#{@key_type.to_s}, #{@value_type.to_s}]"
    end
    def check(value)
      T.check_not_nil(self, value)
      if !value.is_a? Hash
        raise TypeError.new("Value '#{value.inspect.to_s}' type is #{value.class} - Hash is required")
      end
      value.each do |item_key, item_value|
        T.check(@key_type, item_key)
        T.check(@value_type, item_value)
      end
    end
    def ==(other)
      T.instance_of?(HashType, other) and self.key_type == other.key_type and self.value_type == other.value_type
    end
  end

  class StringFormattedType
    attr_reader :regex
    def initialize(regex)
      @regex = regex
    end
    def to_s
      "StringFormatted<#@regex>"
    end
    def check(value)
      T.check_not_nil(self, value)
      if !value.is_a? String
        raise TypeError.new("Value '#{value.inspect.to_s}' type is #{value.class} - String is required for StringFormatted")
      end
      if !@regex.match?(value)
        raise TypeError.new("Value '#{value.inspect.to_s}' is not in required format '#{@regex}'")
      end
    end
  end

  def T.check(type, value)
    if type.methods.include? :check
      type.check(value)
    else
      if type != NilClass
        T.check_not_nil(type, value)
      end
      if !value.is_a? type
        raise TypeError.new("Value '#{value.inspect.to_s}' type is #{value.class} - #{type} is required")
      end
    end
    return value
  end

  def T.instance_of?(type, value)
    begin
      T.check(type, value)
      true
    rescue TypeError
      false
    end
  end

  def T.nilable(value_type)
    NilableType.new(value_type)
  end

  def T.array(item_type)
    ArrayType.new(item_type)
  end

  def T.hash(key_type, value_type)
    HashType.new(key_type, value_type)
  end

  def T.union(*typdefs)
    UnionType.new(*typdefs)
  end

  def T.tagged_union(cases, discriminator=nil)
    TaggedUnionType.new(cases, discriminator)
  end

  def T.check_var(var_name, type, value)
    begin
      check(type, value)
      return value
    rescue TypeError => e
      raise TypeError.new("Variable #{var_name} type check failed, expected type: #{type.to_s}, value: #{value}")
    end
  end
end

Boolean = T.union(TrueClass, FalseClass)
Unknown = T::UnknownType.new
NilableUnknown = T.nilable(Unknown)
UUID = T::StringFormattedType.new(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/)