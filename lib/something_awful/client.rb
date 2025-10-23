# frozen_string_literal: true

require_relative "http/web_client"
require_relative "parsing/post_parser"

class SomethingAwful::Client
  MODS_AND_FORUMS_JSON_URL = "https://forums.somethingawful.com/index.php?json=1"

  def self.fetch_mods_and_forums(cookies_file_path)
    WebClient.new(cookies_file_path: cookies_file_path)
      .fetch_json_url(url: MODS_AND_FORUMS_JSON_URL).fetch("forums")
  end

  def self.fetch_profile(cookies_file_path, something_awful_id:)
    WebClient.new(cookies_file_path: cookies_file_path)
      .fetch_profile(user_id: something_awful_id)
  end

  def initialize(thread_id:, cookies_file_path: nil)
    @thread_id = thread_id
    @cookies_file_path = cookies_file_path
  end

  def user_posts
    posts.select(&:user?)
  end

  def bot_posts
    posts.select(&:bot?)
  end

  def my_posts(after:)
    posts.select do |post|
      next false unless post.timestamp > after

      post.me?
    end
  end

  def reply(text)
    web_client.reply(text)
  end

private

  attr_reader :thread_id, :cookies_file_path

  def web_client
    @web_client ||= WebClient.new(thread_id: thread_id, cookies_file_path: cookies_file_path)
  end

  def posts
    @posts ||= begin
      page = web_client.fetch_page
      posts, page_count = PostParser.posts_for_page(page, page_count: true)
      page_number = 2

      until page_number > page_count
        page = web_client.fetch_page(page_number: page_number)
        posts += PostParser.posts_for_page(page)
        page_number += 1
      end

      posts
    end
  end
end
