# frozen_string_literal: true

require "oga"
require_relative "../models/post"

class PostParser
  class << self
    def posts_for_page(page_html, page_count: false)
      page = parse(page_html)

      posts = page.css(".post").map { |post|
        Post.new(
          author: post.at_css(".author").text,
          id: post.get("id").sub(/^post/, ""),
          text: post.at_css(".postbody").text,
          timestamp: DateTime.parse(post.at_css(".postdate").text),
        )
      }

      if page_count
        [posts, get_page_count(page)]
      else
        posts
      end
    end

  private

    def get_page_count(page)
      page.css(".pages a").last.text.gsub(/\D/, "").to_i
    end

    def parse(page_html)
      Oga.parse_html(page_html.force_encoding("ISO-8859-1").encode("UTF-8"))
    end
  end
end
