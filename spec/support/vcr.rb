require "vcr"
require "webmock/rspec"

VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!

  config.default_cassette_options = {
    record: :new_episodes,
    match_requests_on: %i[method uri body],
  }

  config.filter_sensitive_data("<FILTERED_USERNAME>") { ENV.fetch("SA_USERNAME", nil) }
  config.filter_sensitive_data("<FILTERED_PASSWORD>") { ENV.fetch("SA_PASSWORD", nil) }

  config.filter_sensitive_data("<FILTERED_COOKIE>") do |interaction|
    interaction.response.headers["Set-Cookie"]&.first
  end

  config.before_record do |interaction|
    interaction.request.headers.delete("Cookie")

    if interaction.response.headers["Set-Cookie"]
      interaction.response.headers["Set-Cookie"] = ["<FILTERED_COOKIE>"]
    end
  end

  config.ignore_localhost = true
  config.allow_http_connections_when_no_cassette = false
end
