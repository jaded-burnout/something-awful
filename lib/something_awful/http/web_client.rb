require "http"

class WebClient
  LOGGED_OUT_TRIGGER_TEXT = "CLICK HERE TO REGISTER YOUR ACCOUNT".freeze
  BASE_URL = "https://forums.somethingawful.com".freeze

  def initialize(thread_id: nil, cookies_file_path: nil)
    @thread_id = thread_id
    @cookies_file = if cookies_file_path
      Pathname.new(cookies_file_path)
    else
      "#{Pathname.new(Dir.pwd)}.cookies"
    end

    if cookies_file && File.exist?(cookies_file)
      @cookies = HTTP::CookieJar.new
      @cookies.load(cookies_file.to_s)
    end

    @username = ENV.fetch("SA_USERNAME", nil)
    @password = ENV.fetch("SA_PASSWORD", nil)
  end

  def fetch_json_url(url:)
    response = authenticated_request { |http| http.get(url) }
    JSON.parse(response)
  end

  def fetch_page(page_number: 1, user_id: nil)
    raise "Cannot fetch pages without a thread_id" unless thread_id

    authenticated_request { |http| http.get(thread_url(page_number: page_number, user_id: user_id)) }
  end

  def fetch_profile(user_id:)
    authenticated_request do |http|
      http.get(BASE_URL + "/member.php?action=getinfo&userid=#{user_id}")
    end
  end

  def reply(text)
    raise "Cannot reply without a thread_id" unless thread_id

    reply_form = authenticated_request { |http|
      http.get(BASE_URL + "/newreply.php?action=newreply&threadid=#{thread_id}")
    }

    form_key = extract_value(reply_form, name: "formkey")
    form_cookie = extract_value(reply_form, name: "form_cookie")

    authenticated_request do |http|
      http.post(
        "#{BASE_URL}/newreply.php",
        form: {
          action: "postreply",
          threadid: thread_id,
          formkey: form_key,
          form_cookie: form_cookie,
          message: text,
          submit: "Submit Reply",
        },
      )
    end
  end

  def edit(post_id:, text:)
    authenticated_request do |http|
      http.post(
        "#{BASE_URL}/editpost.php",
        form: {
          action: "updatepost",
          postid: post_id,
          message: text,
          submit: "Save Changes",
        },
      )
    end
  end

private

  attr_reader :thread_id, :cookies_file, :cookies, :username, :password

  def authenticated_request
    log_in unless logged_in?

    http = yield(HTTP.cookies(cookies))
    http.to_s.tap do |body|
      if body.include?(LOGGED_OUT_TRIGGER_TEXT)
        expire_cookies
        log_in
      end
    end
  end

  def log_in
    raise "Cannot log in without a username and password set" if username_or_password_missing?

    puts "Logging in as #{username}"
    response = HTTP.post(
      "#{BASE_URL}/account.php",
      form: {
        action: "login",
        username: username,
        password: password,
      },
    ).flush

    case response.code
    when 302
      if (location = response["location"]).include?("loginerror")
        raise "Error authenticating, redirected to #{location}"
      else
        @cookies = response.cookies
        @cookies.save(cookies_file)
      end
    else
      raise "Unhandled response code: #{response.code}"
    end
  end

  def thread_url(page_number:, user_id: nil)
    url = BASE_URL + "/showthread.php?threadid=#{thread_id}"
    url += "&userid=#{user_id}" if user_id

    if page_number > 1
      url + "&perpage=40&pagenumber=#{page_number}"
    else
      url
    end
  end

  def logged_in?
    !@cookies.nil?
  end

  def username_or_password_missing?
    username.nil? || username.empty? || password.nil? || password.empty?
  end

  def expire_cookies
    @cookies = nil
    cookies_file.truncate(0)
  end

  def extract_value(html, name:)
    if html =~ /name="#{name}" value="([^"]+)"/
      ::Regexp.last_match(1)
    end
  end
end
