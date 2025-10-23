# frozen_string_literal: true

class Record
  class << self
    def attributes(attrs)
      @permitted_attrs = attrs.to_set.freeze
      attrs.each do |attr|
        attr_accessor attr
      end
    end

    attr_reader :permitted_attrs
  end

  def initialize(params = {})
    params.each do |attribute, value|
      next unless self.class.permitted_attrs.include?(attribute)

      public_send("#{attribute}=", value)
    end
  end
end
