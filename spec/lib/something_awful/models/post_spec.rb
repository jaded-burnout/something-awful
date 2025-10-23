require "spec_helper"
require "something_awful/models/post"

RSpec.describe Post do
  describe "attributes" do
    let(:post_params) do
      {
        author: "TestUser",
        id: "12345",
        text: "This is a test post",
        timestamp: DateTime.parse("2025-10-22 12:00:00"),
      }
    end

    it "assigns all permitted attributes" do
      post = described_class.new(post_params)

      expect(post.author).to eq("TestUser")
      expect(post.id).to eq("12345")
      expect(post.text).to eq("This is a test post")
      expect(post.timestamp).to eq(DateTime.parse("2025-10-22 12:00:00"))
    end

    it "ignores non-permitted attributes" do
      post = described_class.new(post_params.merge(invalid_attr: "should be ignored"))

      expect(post).not_to respond_to(:invalid_attr)
    end
  end

  describe "#bot?" do
    context "when author is Adbot" do
      it "returns true" do
        post = described_class.new(author: "Adbot", id: "1", text: "Ad", timestamp: DateTime.now)
        expect(post.bot?).to be true
      end
    end

    context "when author matches bot username from ENV" do
      it "returns true" do
        ClimateControl.modify SA_USERNAME: "BotAccount" do
          post = described_class.new(author: "BotAccount", id: "1", text: "Bot post", timestamp: DateTime.now)
          expect(post.bot?).to be true
        end
      end
    end

    context "when author is a regular user" do
      it "returns false" do
        ClimateControl.modify SA_USERNAME: "BotAccount" do
          post = described_class.new(author: "RegularUser", id: "1", text: "User post", timestamp: DateTime.now)
          expect(post.bot?).to be false
        end
      end
    end

    context "when SA_USERNAME env var is not set" do
      it "only identifies Adbot as bot" do
        ClimateControl.modify SA_USERNAME: nil do
          adbot_post = described_class.new(author: "Adbot", id: "1", text: "Ad", timestamp: DateTime.now)
          user_post = described_class.new(author: "SomeUser", id: "2", text: "Post", timestamp: DateTime.now)

          expect(adbot_post.bot?).to be true
          expect(user_post.bot?).to be false
        end
      end
    end
  end

  describe "#user?" do
    it "returns the opposite of #bot?" do
      bot_post = described_class.new(author: "Adbot", id: "1", text: "Ad", timestamp: DateTime.now)
      user_post = described_class.new(author: "RegularUser", id: "2", text: "Post", timestamp: DateTime.now)

      expect(bot_post.user?).to be false
      expect(user_post.user?).to be true
    end
  end

  describe "#me?" do
    context "when author matches SA_USERNAME" do
      it "returns true" do
        ClimateControl.modify SA_USERNAME: "MyUsername" do
          post = described_class.new(author: "MyUsername", id: "1", text: "My post", timestamp: DateTime.now)
          expect(post.me?).to be true
        end
      end
    end

    context "when author doesn't match SA_USERNAME" do
      it "returns false" do
        ClimateControl.modify SA_USERNAME: "MyUsername" do
          post = described_class.new(author: "OtherUser", id: "1", text: "Their post", timestamp: DateTime.now)
          expect(post.me?).to be false
        end
      end
    end

    context "when SA_USERNAME is not set" do
      it "returns false" do
        ClimateControl.modify SA_USERNAME: nil do
          post = described_class.new(author: "SomeUser", id: "1", text: "Post", timestamp: DateTime.now)
          expect(post.me?).to be false
        end
      end
    end
  end
end
