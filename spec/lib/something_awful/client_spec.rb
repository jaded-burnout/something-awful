require "spec_helper"
require "something_awful/client"

RSpec.describe SomethingAwful::Client do
  let(:thread_id) { "123456" }
  let(:cookies_file_path) { File.join(Dir.tmpdir, "test_cookies_#{Time.now.to_i}.txt") }
  let(:client) { described_class.new(thread_id: thread_id, cookies_file_path: cookies_file_path) }
  let(:thread_html_single) { SomethingAwful.root.join("spec/fixtures/thread_page_single.html").read }
  let(:thread_html) { SomethingAwful.root.join("spec/fixtures/thread_page.html").read }
  let(:thread_page_2_html) { SomethingAwful.root.join("spec/fixtures/thread_page_2.html").read }

  after do
    FileUtils.rm_f(cookies_file_path)
  end

  before do
    allow_any_instance_of(WebClient).to receive(:cookies_file).and_return(Pathname.new(cookies_file_path))

    ClimateControl.modify SA_USERNAME: "testuser", SA_PASSWORD: "testpass" do
      stub_request(:post, "#{WebClient::BASE_URL}/account.php")
        .to_return(status: 302, headers: { "location" => WebClient::BASE_URL, "Set-Cookie" => "session=abc123" })
    end
  end

  describe ".fetch_mods_and_forums" do
    let(:json_response) do
      {
        "forums" => [
          { "id" => 1, "name" => "General Discussion" },
          { "id" => 2, "name" => "Games" },
        ],
      }.to_json
    end

    before do
      ClimateControl.modify SA_USERNAME: "testuser", SA_PASSWORD: "testpass" do
        stub_request(:get, SomethingAwful::Client::MODS_AND_FORUMS_JSON_URL)
          .to_return(status: 200, body: json_response)
      end
    end

    it "fetches and returns forum data" do
      ClimateControl.modify SA_USERNAME: "testuser", SA_PASSWORD: "testpass" do
        result = described_class.fetch_mods_and_forums(cookies_file_path)

        expect(result).to be_an(Array)
        expect(result.length).to eq(2)
        expect(result.first["name"]).to eq("General Discussion")
      end
    end
  end

  describe ".fetch_profile" do
    let(:user_id) { "12345" }
    let(:profile_html) { "<html><body>User Profile for ID #{user_id}</body></html>" }

    before do
      ClimateControl.modify SA_USERNAME: "testuser", SA_PASSWORD: "testpass" do
        stub_request(:get, "#{WebClient::BASE_URL}/member.php?action=getinfo&userid=#{user_id}")
          .to_return(status: 200, body: profile_html)
      end
    end

    it "fetches user profile by ID" do
      ClimateControl.modify SA_USERNAME: "testuser", SA_PASSWORD: "testpass" do
        result = described_class.fetch_profile(cookies_file_path, something_awful_id: user_id)

        expect(result).to include("User Profile")
        expect(result).to include(user_id)
      end
    end
  end

  describe "#user_posts" do
    before do
      ClimateControl.modify SA_USERNAME: "testuser", SA_PASSWORD: "testpass" do
        stub_request(:get, "#{WebClient::BASE_URL}/showthread.php?threadid=#{thread_id}")
          .to_return(status: 200, body: thread_html_single)
      end
    end

    it "returns only non-bot posts" do
      ClimateControl.modify SA_USERNAME: "testuser", SA_PASSWORD: "testpass" do
        posts = client.user_posts

        expect(posts.length).to eq(3)
        expect(posts.map(&:author)).to eq(%w[TestUser1 TestUser2 TestUser3])
        expect(posts.none?(&:bot?)).to be true
      end
    end
  end

  describe "#bot_posts" do
    before do
      ClimateControl.modify SA_USERNAME: "testuser", SA_PASSWORD: "testpass" do
        stub_request(:get, "#{WebClient::BASE_URL}/showthread.php?threadid=#{thread_id}")
          .to_return(status: 200, body: thread_html_single)
      end
    end

    it "returns only bot posts" do
      ClimateControl.modify SA_USERNAME: "testuser", SA_PASSWORD: "testpass" do
        posts = client.bot_posts

        expect(posts.length).to eq(1)
        expect(posts.first.author).to eq("Adbot")
        expect(posts.all?(&:bot?)).to be true
      end
    end
  end

  describe "#my_posts" do
    let(:cutoff_time) { DateTime.parse("Oct 22, 2025 11:00") }

    before do
      ClimateControl.modify SA_USERNAME: "testuser", SA_PASSWORD: "testpass" do
        stub_request(:get, "#{WebClient::BASE_URL}/showthread.php?threadid=#{thread_id}")
          .to_return(status: 200, body: thread_html_single)
      end
    end

    it "returns posts after cutoff time authored by the current user" do
      ClimateControl.modify SA_USERNAME: "TestUser2", SA_PASSWORD: "testpass" do
        posts = client.my_posts(after: cutoff_time)

        expect(posts.length).to eq(1)
        expect(posts.first.author).to eq("TestUser2")
        expect(posts.all? { |p| p.timestamp > cutoff_time }).to be true
      end
    end
  end

  describe "#reply" do
    let(:reply_form_html) { SomethingAwful.root.join("spec/fixtures/reply_form.html").read }
    let(:reply_text) { "Test reply from client" }

    before do
      ClimateControl.modify SA_USERNAME: "testuser", SA_PASSWORD: "testpass" do
        stub_request(:get, "#{WebClient::BASE_URL}/newreply.php?action=newreply&threadid=#{thread_id}")
          .to_return(status: 200, body: reply_form_html)

        stub_request(:post, "#{WebClient::BASE_URL}/newreply.php")
          .to_return(status: 302, headers: { "location" => "#{WebClient::BASE_URL}/showthread.php?threadid=#{thread_id}" })
      end
    end

    it "delegates to WebClient#reply" do
      ClimateControl.modify SA_USERNAME: "testuser", SA_PASSWORD: "testpass" do
        result = client.reply(reply_text)
        expect(result).to be_a(String)
      end
    end
  end

  describe "fetching multiple pages" do
    let(:thread_page_3_html) { '<html><body><div class="pages"><a>1</a><a>2</a></div></body></html>' }

    before do
      ClimateControl.modify SA_USERNAME: "testuser", SA_PASSWORD: "testpass" do
        stub_request(:get, "#{WebClient::BASE_URL}/showthread.php?threadid=#{thread_id}")
          .to_return(status: 200, body: thread_html)

        stub_request(:get, "#{WebClient::BASE_URL}/showthread.php?threadid=#{thread_id}&perpage=40&pagenumber=2")
          .to_return(status: 200, body: thread_page_2_html)

        stub_request(:get, "#{WebClient::BASE_URL}/showthread.php?threadid=#{thread_id}&perpage=40&pagenumber=3")
          .to_return(status: 200, body: thread_page_3_html)
      end
    end

    it "fetches all pages and combines posts" do
      ClimateControl.modify SA_USERNAME: "testuser", SA_PASSWORD: "testpass" do
        posts = client.user_posts

        expect(posts.length).to eq(5)

        first_page_posts = posts.select { |p| %w[TestUser1 TestUser2 TestUser3].include?(p.author) }
        second_page_posts = posts.select { |p| %w[TestUser4 TestUser5].include?(p.author) }

        expect(first_page_posts.length).to eq(3)
        expect(second_page_posts.length).to eq(2)
      end
    end
  end

  describe "initialization" do
    it "requires a thread_id" do
      expect { described_class.new(thread_id: thread_id) }.not_to raise_error
    end

    it "stores the thread_id" do
      client = described_class.new(thread_id: "999")
      expect(client.instance_variable_get(:@thread_id)).to eq("999")
    end
  end
end
