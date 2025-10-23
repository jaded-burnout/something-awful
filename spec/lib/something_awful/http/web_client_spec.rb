require "spec_helper"
require "something_awful/http/web_client"

RSpec.describe WebClient do
  let(:thread_id) { "123456" }
  let(:cookies_file_path) { File.join(Dir.tmpdir, "test_cookies_#{Time.now.to_i}.txt") }

  after do
    FileUtils.rm_f(cookies_file_path)
  end

  describe "#initialize" do
    context "with cookies file that exists" do
      before do
        File.write(cookies_file_path, "# test cookies\n")
      end

      it "loads cookies from file" do
        client = described_class.new(thread_id: thread_id, cookies_file_path: cookies_file_path)
        expect(client).to be_a(described_class)
      end
    end

    context "with cookies file that doesn't exist" do
      it "initializes without loading cookies" do
        client = described_class.new(thread_id: thread_id, cookies_file_path: cookies_file_path)
        expect(client).to be_a(described_class)
      end
    end

    context "without thread_id" do
      it "can still be initialized" do
        client = described_class.new(cookies_file_path: cookies_file_path)
        expect(client).to be_a(described_class)
      end
    end
  end

  describe "#fetch_page" do
    let(:client) { described_class.new(thread_id: thread_id, cookies_file_path: cookies_file_path) }
    let(:thread_html) { SomethingAwful.root.join("spec/fixtures/thread_page.html").read }

    context "without a thread_id" do
      let(:client) { described_class.new(cookies_file_path: cookies_file_path) }

      it "raises an error" do
        expect { client.fetch_page }.to raise_error(/Cannot fetch pages without a thread_id/)
      end
    end

    context "with authentication", vcr: { cassette_name: "fetch_page" } do
      before do
        ClimateControl.modify SA_USERNAME: "testuser", SA_PASSWORD: "testpass" do
          stub_request(:post, "#{WebClient::BASE_URL}/account.php")
            .to_return(status: 302, headers: { "location" => WebClient::BASE_URL, "Set-Cookie" => "session=abc123" })

          stub_request(:get, "#{WebClient::BASE_URL}/showthread.php?threadid=#{thread_id}")
            .to_return(status: 200, body: thread_html)
        end
      end

      it "fetches the thread page" do
        ClimateControl.modify SA_USERNAME: "testuser", SA_PASSWORD: "testpass" do
          result = client.fetch_page
          expect(result).to include("Test Thread")
        end
      end
    end

    context "with page number", vcr: { cassette_name: "fetch_page_2" } do
      let(:thread_page_2_html) { SomethingAwful.root.join("spec/fixtures/thread_page_2.html").read }

      before do
        ClimateControl.modify SA_USERNAME: "testuser", SA_PASSWORD: "testpass" do
          stub_request(:post, "#{WebClient::BASE_URL}/account.php")
            .to_return(status: 302, headers: { "location" => WebClient::BASE_URL, "Set-Cookie" => "session=abc123" })

          stub_request(:get, "#{WebClient::BASE_URL}/showthread.php?threadid=#{thread_id}&perpage=40&pagenumber=2")
            .to_return(status: 200, body: thread_page_2_html)
        end
      end

      it "fetches the specified page" do
        ClimateControl.modify SA_USERNAME: "testuser", SA_PASSWORD: "testpass" do
          result = client.fetch_page(page_number: 2)
          expect(result).to include("Page 2")
        end
      end
    end
  end

  describe "#fetch_profile" do
    let(:client) { described_class.new(cookies_file_path: cookies_file_path) }
    let(:user_id) { "12345" }
    let(:profile_html) { "<html><body>User Profile</body></html>" }

    before do
      ClimateControl.modify SA_USERNAME: "testuser", SA_PASSWORD: "testpass" do
        stub_request(:post, "#{WebClient::BASE_URL}/account.php")
          .to_return(status: 302, headers: { "location" => WebClient::BASE_URL, "Set-Cookie" => "session=abc123" })

        stub_request(:get, "#{WebClient::BASE_URL}/member.php?action=getinfo&userid=#{user_id}")
          .to_return(status: 200, body: profile_html)
      end
    end

    it "fetches user profile", vcr: { cassette_name: "fetch_profile" } do
      ClimateControl.modify SA_USERNAME: "testuser", SA_PASSWORD: "testpass" do
        result = client.fetch_profile(user_id: user_id)
        expect(result).to include("User Profile")
      end
    end
  end

  describe "#fetch_json_url" do
    let(:client) { described_class.new(cookies_file_path: cookies_file_path) }
    let(:json_url) { "#{WebClient::BASE_URL}/index.php?json=1" }
    let(:json_response) { '{"forums": [{"id": 1, "name": "Test Forum"}]}' }

    before do
      ClimateControl.modify SA_USERNAME: "testuser", SA_PASSWORD: "testpass" do
        stub_request(:post, "#{WebClient::BASE_URL}/account.php")
          .to_return(status: 302, headers: { "location" => WebClient::BASE_URL, "Set-Cookie" => "session=abc123" })

        stub_request(:get, json_url)
          .to_return(status: 200, body: json_response)
      end
    end

    it "fetches and parses JSON", vcr: { cassette_name: "fetch_json" } do
      ClimateControl.modify SA_USERNAME: "testuser", SA_PASSWORD: "testpass" do
        result = client.fetch_json_url(url: json_url)
        expect(result).to be_a(Hash)
        expect(result["forums"]).to be_an(Array)
      end
    end
  end

  describe "#reply" do
    let(:client) { described_class.new(thread_id: thread_id, cookies_file_path: cookies_file_path) }
    let(:reply_form_html) { SomethingAwful.root.join("spec/fixtures/reply_form.html").read }
    let(:reply_text) { "Test reply message" }

    context "without a thread_id" do
      let(:client) { described_class.new(cookies_file_path: cookies_file_path) }

      it "raises an error" do
        expect { client.reply(reply_text) }.to raise_error(/Cannot reply without a thread_id/)
      end
    end

    context "with valid credentials", vcr: { cassette_name: "reply_to_thread" } do
      before do
        ClimateControl.modify SA_USERNAME: "testuser", SA_PASSWORD: "testpass" do
          stub_request(:post, "#{WebClient::BASE_URL}/account.php")
            .to_return(status: 302, headers: { "location" => WebClient::BASE_URL, "Set-Cookie" => "session=abc123" })

          stub_request(:get, "#{WebClient::BASE_URL}/newreply.php?action=newreply&threadid=#{thread_id}")
            .to_return(status: 200, body: reply_form_html)

          stub_request(:post, "#{WebClient::BASE_URL}/newreply.php")
            .to_return(status: 302, headers: { "location" => "#{WebClient::BASE_URL}/showthread.php?threadid=#{thread_id}" })
        end
      end

      it "posts a reply to the thread" do
        ClimateControl.modify SA_USERNAME: "testuser", SA_PASSWORD: "testpass" do
          result = client.reply(reply_text)
          expect(result).to be_a(String)
        end
      end
    end
  end

  describe "#edit" do
    let(:client) { described_class.new(thread_id: thread_id, cookies_file_path: cookies_file_path) }
    let(:post_id) { "12345" }
    let(:edit_text) { "Updated post content" }

    context "with valid credentials" do
      before do
        ClimateControl.modify SA_USERNAME: "testuser", SA_PASSWORD: "testpass" do
          stub_request(:post, "#{WebClient::BASE_URL}/account.php")
            .to_return(status: 302, headers: { "location" => WebClient::BASE_URL, "Set-Cookie" => "session=abc123" })

          stub_request(:post, "#{WebClient::BASE_URL}/editpost.php")
            .with(body: hash_including(
              "action" => "updatepost",
              "postid" => post_id,
              "message" => edit_text,
            ),
                 )
            .to_return(status: 302, headers: { "location" => "#{WebClient::BASE_URL}/showthread.php?threadid=#{thread_id}" })
        end
      end

      it "edits the post" do
        ClimateControl.modify SA_USERNAME: "testuser", SA_PASSWORD: "testpass" do
          result = client.edit(post_id: post_id, text: edit_text)
          expect(result).to be_a(String)
        end
      end
    end
  end

  describe "authentication" do
    let(:client) { described_class.new(thread_id: thread_id, cookies_file_path: cookies_file_path) }

    context "when credentials are missing" do
      it "raises an error when trying to authenticate" do
        ClimateControl.modify SA_USERNAME: nil, SA_PASSWORD: nil do
          expect {
            client.fetch_page
          }.to raise_error(/Cannot log in without a username and password set/)
        end
      end
    end

    context "when login fails" do
      before do
        ClimateControl.modify SA_USERNAME: "baduser", SA_PASSWORD: "badpass" do
          stub_request(:post, "#{WebClient::BASE_URL}/account.php")
            .to_return(status: 302, headers: { "location" => "#{WebClient::BASE_URL}/account.php?loginerror=1" })
        end
      end

      it "raises an error" do
        ClimateControl.modify SA_USERNAME: "baduser", SA_PASSWORD: "badpass" do
          expect {
            client.fetch_page
          }.to raise_error(/Error authenticating/)
        end
      end
    end
  end
end
