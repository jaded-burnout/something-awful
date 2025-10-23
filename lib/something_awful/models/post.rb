# frozen_string_literal: true

require_relative "record"

class Post < Record
  ADBOT = "Adbot"

  attributes %I[
    author
    id
    text
    timestamp
  ]

  def bot?
    [ADBOT, bot_name].compact.reject { |name| name.nil? || name.empty? }.include?(author)
  end

  def user?
    !bot?
  end

  def me?
    author == ENV["SA_USERNAME"]
  end

private

  def bot_name
    ENV.fetch("SA_USERNAME", nil)
  end
end
