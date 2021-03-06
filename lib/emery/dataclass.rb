module DataClass
  def initialize(params)
    self.class.json_attributes.each do |attr, attr_type|
      attr_value = params[attr]
      self.instance_variable_set("@#{attr}", T.check_var(attr, attr_type, attr_value))
    end
  end

  def ==(other)
    begin
      T.check(self.class, other)
      self.class.json_attributes.keys.each do |attr|
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
    params.each do |attr, attr_value|
      if !self.class.json_attributes.key?(attr)
        raise TypeError.new("Non existing attribute #{attr}")
      end
    end
    new_params =
      self.class.json_attributes.map do |attr, attr_type|
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
  end

  module ClassMethods
    def json_attributes
      @json_attributes
    end

    def val(name, type)
      if @json_attributes == nil
        @json_attributes = {}
      end
      @json_attributes[name] = type
      attr_reader name
    end

    def var(name, type)
      if @json_attributes == nil
        @json_attributes = {}
      end
      @json_attributes[name] = type
      attr_accessor name
    end

    def jsoner_deserialize(json_value)
      T.check(T.hash(String, NilableUntyped), json_value)
      parameters = @json_attributes.map do |attr, attr_type|
        attr_value = json_value[attr.to_s]
        [attr, Jsoner.deserialize(attr_type, attr_value)]
      end
      return self.new parameters.to_h
    end

    def jsoner_serialize(value)
      T.check(self, value)
      attrs = @json_attributes.map do |attr, attr_type|
        [attr, Jsoner.serialize(attr_type, value.send(attr))]
      end
      return attrs.to_h
    end
  end
end