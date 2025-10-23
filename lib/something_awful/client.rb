# frozen_string_literal: true

require_relative "http/web_client"
require_relative "parsing/post_parser"

class SomethingAwful::Client
  MODS_AND_FORUMS_JSON_URL = "https://forums.somethingawful.com/index.php?json=1"

  def self.fetch_mods_and_forums(cookies_file_path)
    WebClient.new(cookies_file_path:)
      .fetch_json_url(url: MODS_AND_FORUMS_JSON_URL).fetch("forums")
  end

  def self.fetch_profile(cookies_file_path, something_awful_id:)
    WebClient.new(cookies_file_path:)
      .fetch_profile(user_id: something_awful_id)
  end

  def initialize(thread_id:, cookies_file_path: nil)
    @thread_id = thread_id
    @cookies_file_path = cookies_file_path
  end

  def user_posts
    return enum_for(:user_posts) unless block_given?

    each_post { |post| yield(post) if post.user? }
  end

  def bot_posts
    return enum_for(:bot_posts) unless block_given?

    each_post { |post| yield(post) if post.bot? }
  end

  def my_posts(after:)
    return enum_for(:my_posts, after:) unless block_given?

    each_post do |post|
      yield(post) if post.timestamp > after && post.me?
    end
  end

  def reply(text)
    web_client.reply(text)
  end

  def edit_post(post_id:, text: nil, &)
    web_client.edit(post_id:, text:, &)
  end

  def posts_by_user(user_id:, &)
    return enum_for(:posts_by_user, user_id:) unless block_given?

    each_post(user_id:, &)
  end

  def each_post(user_id: nil, &)
    return enum_for(:each_post, user_id:) unless block_given?

    page_number = 1
    loop do
      page_html = web_client.fetch_page(page_number:, user_id:)
      posts, page_count = PostParser.posts_for_page(page_html, page_count: true)

      posts.each(&)

      break if page_number >= page_count

      page_number += 1
    end
  end

  def fetch_page(page_number: 1, user_id: nil)
    page_html = web_client.fetch_page(page_number:, user_id:)
    PostParser.posts_for_page(page_html, page_count: true)
  end

private

  attr_reader :thread_id, :cookies_file_path

  def web_client
    @web_client ||= WebClient.new(thread_id:, cookies_file_path:)
  end
end
