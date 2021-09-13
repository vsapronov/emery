module DataClass
  def initialize(params)
    self.class.typed_attributes.each do |attr, attr_type|
      attr_value = params[attr]
      self.instance_variable_set("@#{attr}", T.check_var(attr, attr_type, attr_value))
    end
  end

  def ==(other)
    begin
      T.check(self.class, other)
      self.class.typed_attributes.keys.each do |attr|
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
      if !self.class.typed_attributes.key?(attr)
        raise TypeError.new("Non existing attribute #{attr}")
      end
    end
    new_params =
      self.class.typed_attributes.keys.map do |attr|
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
    def typed_attributes
      @typed_attributes
    end

    def val(name, type)
      if @typed_attributes == nil
        @typed_attributes = {}
      end
      @typed_attributes[name] = type
      attr_reader name
    end

    def var(name, type)
      if @typed_attributes == nil
        @typed_attributes = {}
      end
      @typed_attributes[name] = type
      attr_accessor name
    end
  end
end