require "something_awful/version"
require "something_awful/client"
require "something_awful/configuration"

module SomethingAwful
  class Error < StandardError; end

  def self.root
    Pathname.new(File.join(File.dirname(__FILE__), ".."))
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration)
  end

  def self.reset_configuration!
    @configuration = Configuration.new
  end
end
