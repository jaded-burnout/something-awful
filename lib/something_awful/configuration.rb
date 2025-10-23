# frozen_string_literal: true

module SomethingAwful
  class Configuration
    attr_accessor :backup_path

    def initialize
      @backup_path = nil
    end
  end
end
