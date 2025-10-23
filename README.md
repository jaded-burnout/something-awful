# SomethingAwful

A Ruby client library for interacting with the Something Awful forums via web scraping. This gem provides a simple interface for reading posts, fetching user profiles, and posting replies to threads.

## Overview

**⚠️ Important:** This gem interacts with Something Awful forums through web scraping (not an official API). Use responsibly and be aware of the forum's terms of service. The gem includes safety mechanisms like cookie-based authentication and VCR for testing to minimise unnecessary requests.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'something_awful'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install something_awful

## Authentication

The gem uses cookie-based authentication with username/password credentials. Set these as environment variables:

```bash
export SA_USERNAME="your_sa_username"
export SA_PASSWORD="your_sa_password"
```

Cookies are automatically saved to a `.cookies` file (gitignored) and reused for subsequent requests to avoid unnecessary logins.

## Usage

### Basic Client Setup

```ruby
require 'something_awful'

# Initialize a client for a specific thread
client = SomethingAwful::Client.new(thread_id: "3765007")
```

### Fetching Posts

```ruby
# Get all user posts (excludes bots like Adbot)
user_posts = client.user_posts

# Get all bot posts
bot_posts = client.bot_posts

# Get posts after a specific timestamp
require 'date'
cutoff_time = DateTime.parse("2025-10-22 12:00:00")
recent_posts = client.my_posts(after: cutoff_time)

# Access post attributes
user_posts.each do |post|
  puts "Author: #{post.author}"
  puts "ID: #{post.id}"
  puts "Text: #{post.text}"
  puts "Posted at: #{post.timestamp}"
  puts "Is bot?: #{post.bot?}"
  puts "---"
end
```

### Posting Replies

**⚠️ Warning:** This performs write operations on the live forum. Use with extreme caution.

```ruby
client = SomethingAwful::Client.new(thread_id: "3765007")
client.reply("This is my reply text")
```

### Finding Your Posts

```ruby
# Get posts you authored after a certain time
my_posts = client.my_posts(after: DateTime.parse("2025-10-22 12:00:00"))

my_posts.each do |post|
  puts "I posted: #{post.text} at #{post.timestamp}"
end
```

### Fetching User Profiles

```ruby
# Requires a cookies file for authentication
cookies_file = "/path/to/.cookies"
profile_html = SomethingAwful::Client.fetch_profile(
  cookies_file,
  something_awful_id: "12345"
)
```

### Fetching Forums and Moderators

```ruby
cookies_file = "/path/to/.cookies"
forums = SomethingAwful::Client.fetch_mods_and_forums(cookies_file)

forums.each do |forum|
  puts "Forum: #{forum['name']}"
end
```

### Instant Runoff Voting

The gem includes a standalone instant runoff voting system for ranked-choice elections:

```ruby
require 'something_awful/voting/instant_runoff'

votes = [
  ["Candidate A", "Candidate B", "Candidate C"],
  ["Candidate B", "Candidate A"],
  ["Candidate A", "Candidate C"],
  ["Candidate C", "Candidate A"]
]

election = InstantRunoff.new(votes: votes)
puts election.report
```

Output example:
```
Round 1

Candidate A: 2/4 (50.0%)
Candidate B: 1/4 (25.0%)
Candidate C: 1/4 (25.0%)

No majority found. Candidate B and Candidate C are eliminated.

Round 2

Candidate A: 4/4 (100.0%)

Ballot complete. Candidate A wins.
```

## Architecture

### Components

- **`SomethingAwful::Client`**: Main interface for thread operations
- **`WebClient`**: Handles HTTP requests, authentication, and cookie management
- **`PostParser`**: Parses HTML pages into Post objects using Oga
- **`Post`**: Model representing a forum post with attributes (author, id, text, timestamp)
- **`Record`**: Base model class with attribute definition DSL
- **`InstantRunoff`**: Standalone instant runoff voting system

### How It Works

1. **Authentication**: Uses HTTP gem to POST credentials to `/account.php`, saves cookies
2. **Cookie Management**: Cookies stored in file, reloaded on initialization
3. **Page Fetching**: GET requests to `/showthread.php` with thread_id parameter
4. **Parsing**: Oga parses HTML, extracts post elements by CSS selectors (`.post`, `.author`, `.postbody`, `.postdate`)
5. **Multi-page Support**: Automatically detects page count and fetches all pages
6. **Encoding**: Handles ISO-8859-1 to UTF-8 conversion for proper character encoding

## Development

After checking out the repo, run `bin/setup` to install dependencies.

### Running Tests

```bash
bundle exec rspec
```

Tests use VCR and WebMock to stub HTTP requests, ensuring no accidental live forum interactions during testing.

### Interactive Console

```bash
bin/console
```

### Testing Against Live Site

**⚠️ Extreme Caution Required**

The test suite is designed to use stubs by default. If you need to capture real interactions:

1. Set your credentials: `export USERNAME="..." PASSWORD="..."`
2. VCR will record new HTTP interactions to `spec/fixtures/vcr_cassettes/`
3. 2. **VCR cassettes contain only synthetic data** (see `spec/fixtures/vcr_cassettes/README.md`)
3. **Always anonymise captured data before committing** (usernames, IDs, cookies, content)
4. **Read-only by default** - posting requires explicit method calls
4. Review all cassettes manually to ensure no sensitive data

## Safety Features

- **VCR Integration**: Records HTTP interactions for replay, avoiding repeated live requests
- **WebMock**: Blocks all HTTP requests by default in tests unless explicitly stubbed
- **Credential Filtering**: VCR automatically filters `USERNAME`, `PASSWORD`, and cookies from cassettes
- **Cookie Persistence**: Avoids unnecessary logins by reusing session cookies
- **Anonymous Fixtures**: Test fixtures use fabricated data, not real forum content

## Known Limitations

- No official API support (web scraping only)
- HTML structure changes on SA forums will break parsing
- No edit post functionality (yet)
- Rate limiting not implemented (be respectful)
- Encoding issues possible with non-UTF-8 content

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/jaded-burnout/something-awful.

When contributing:
- Write tests for new features
- Use VCR for any HTTP interactions
- Anonymise any real forum data in fixtures
- Follow the existing code style
- Be extra cautious with write operations

## License

See the LICENSE file (if present) for details.

## Disclaimer

This gem is not affiliated with or endorsed by Something Awful or its operators. Use at your own risk and in accordance with the forum's terms of service.
