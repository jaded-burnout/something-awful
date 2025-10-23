require "spec_helper"
require "something_awful/parsing/post_parser"

RSpec.describe PostParser do
  let(:thread_page_html) { SomethingAwful.root.join("spec/fixtures/thread_page.html").read }
  let(:thread_page_2_html) { SomethingAwful.root.join("spec/fixtures/thread_page_2.html").read }

  describe ".posts_for_page" do
    context "without page_count option" do
      it "returns an array of Post objects" do
        posts = described_class.posts_for_page(thread_page_html)

        expect(posts).to be_an(Array)
        expect(posts.length).to eq(4)
        expect(posts.all? { |p| p.is_a?(Post) }).to be true
      end

      it "extracts post attributes correctly" do
        posts = described_class.posts_for_page(thread_page_html)

        first_post = posts.first
        expect(first_post.id).to eq("12345")
        expect(first_post.author).to eq("TestUser1")
        expect(first_post.text).to eq("This is the first test post content.")
        expect(first_post.timestamp).to eq(DateTime.parse("Oct 22, 2025 10:30"))
      end

      it "parses all posts on the page" do
        posts = described_class.posts_for_page(thread_page_html)

        expect(posts.map(&:author)).to eq(%w[TestUser1 TestUser2 Adbot TestUser3])
        expect(posts.map(&:id)).to eq(%w[12345 12346 12347 12348])
      end

      it "strips post ID prefix correctly" do
        posts = described_class.posts_for_page(thread_page_html)

        posts.each do |post|
          expect(post.id).not_to start_with("post")
          expect(post.id).to match(/^\d+$/)
        end
      end

      it "parses timestamps as DateTime objects" do
        posts = described_class.posts_for_page(thread_page_html)

        posts.each do |post|
          expect(post.timestamp).to be_a(DateTime)
        end
      end
    end

    context "with page_count: true option" do
      it "returns both posts array and page count" do
        result = described_class.posts_for_page(thread_page_html, page_count: true)

        expect(result).to be_an(Array)
        expect(result.length).to eq(2)

        posts, page_count = result
        expect(posts).to be_an(Array)
        expect(page_count).to be_an(Integer)
      end

      it "extracts correct page count from pagination" do
        _posts, page_count = described_class.posts_for_page(thread_page_html, page_count: true)

        expect(page_count).to eq(3)
      end

      it "still returns all posts correctly" do
        posts, _page_count = described_class.posts_for_page(thread_page_html, page_count: true)

        expect(posts.length).to eq(4)
        expect(posts.map(&:author)).to eq(%w[TestUser1 TestUser2 Adbot TestUser3])
      end
    end

    context "with different page" do
      it "parses posts from second page correctly" do
        posts, page_count = described_class.posts_for_page(thread_page_2_html, page_count: true)

        expect(posts.length).to eq(2)
        expect(posts.map(&:id)).to eq(%w[12349 12350])
        expect(posts.map(&:author)).to eq(%w[TestUser4 TestUser5])
        expect(page_count).to eq(2)
      end
    end

    context "with malformed HTML" do
      let(:minimal_html) do
        <<~HTML
          <html>
            <body>
              <div class="pages"><a>1</a></div>
              <div class="post" id="post999">
                <div class="author">TestUser</div>
                <div class="postdate">Oct 22, 2025 12:00</div>
                <div class="postbody">Test content</div>
              </div>
            </body>
          </html>
        HTML
      end

      it "still extracts posts successfully" do
        posts = described_class.posts_for_page(minimal_html)

        expect(posts.length).to eq(1)
        expect(posts.first.id).to eq("999")
        expect(posts.first.author).to eq("TestUser")
      end
    end

    context "with no posts" do
      let(:empty_page) do
        <<~HTML
          <html>
            <body>
              <div class="pages"><a>1</a></div>
            </body>
          </html>
        HTML
      end

      it "returns an empty array" do
        posts = described_class.posts_for_page(empty_page)

        expect(posts).to eq([])
      end
    end

    context "with encoding issues" do
      it "handles ISO-8859-1 to UTF-8 conversion" do
        iso_html = thread_page_html.force_encoding("ISO-8859-1")

        posts = described_class.posts_for_page(iso_html)

        expect(posts.length).to eq(4)
        expect(posts.first.text.encoding.name).to eq("UTF-8")
      end
    end
  end
end
