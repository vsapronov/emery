module TaggedUnion
  def initialize(params)
    if params.length != 1
      raise ArgumentError.new("Tagged union #{self.class} should have one only one tag set, found #{params.length}" )
    end

    tag = params.keys[0]
    tag_type = self.class.typed_tags[tag]
    tag_value = T.check_var(tag, tag_type, params[tag])
    self.instance_variable_set("@#{tag}", tag_value)
    self.current_tag = tag
    self.current_value = tag_value
  end

  def ==(other)
    begin
      T.check(self.class, other)
      self.class.typed_tags.keys.each do |attr|
        if self.instance_variable_get("@#{attr}") != other.instance_variable_get("@#{attr}")
          return false
        end
      end
      return true
    rescue
      return false
    end
  end

  def copy(params)
    params.keys.each do |attr|
      if !self.class.typed_tags.key?(attr)
        raise TypeError.new("Non existing attribute #{attr}")
      end
    end
    new_params =
      self.class.typed_tags.keys.map do |attr|
        attr_value =
          if params.key?(attr)
            params[attr]
          else
            self.instance_variable_get("@#{attr}")
          end
        [attr, attr_value]
      end.to_h
    return self.class.new(new_params)
  end

  def to_json
    return Jsoner.serialize(self.class, self)
  end

  def self.included(base)
    base.extend ClassMethods
    attr_accessor :current_tag
    attr_accessor :current_value
  end

  module ClassMethods
    def typed_tags
      @typed_tags
    end

    def tag(name, type)
      if @typed_tags == nil
        @typed_tags = {}
      end
      @typed_tags[name] = type
      attr_accessor name
    end

    def discriminator
      @discriminator
    end

    def with_discriminator(value)
      @discriminator = value
    end
  end
end