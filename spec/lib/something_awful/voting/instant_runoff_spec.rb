require "spec_helper"

require "voting/instant_runoff"

RSpec.describe InstantRunoff do
  subject(:runoff) { described_class.new(votes:) }

  context "when the dog candidate has more than 50% of the vote in the first round" do
    let(:votes) {
      [
        %w[
          Dog
          Cat
        ],
        %w[
          Dog
          Rat
        ],
        [
          "Cat",
        ],
      ]
    }

    it "provides a full text report showing the dog as the winner" do
      expect(runoff.report).to eq(
        <<~REPORT,
          Round 1

          Dog: 2/3 (66.67%)
          Cat: 1/3 (33.33%)

          Ballot complete.  Dog wins.
        REPORT
      )
    end
  end

  context "when the cat candidate has more than 50% of the vote after two rounds" do
    let(:votes) {
      [
        %w[
          Rat
          Cat
        ],
        %w[
          Dog
          Cat
        ],
        [
          "Cat",
        ],
        %w[
          Cat
          Rat
        ],
      ]
    }

    it "provides a full text report showing the cat as the winner" do
      expect(runoff.report).to eq(
        <<~REPORT,
          Round 1

          Cat: 2/4 (50.0%)
          Dog: 1/4 (25.0%)
          Rat: 1/4 (25.0%)

          No majority found.  Dog and Rat are eliminated.

          Round 2

          Cat: 4/4 (100.0%)

          Ballot complete.  Cat wins.
        REPORT
      )
    end
  end

  context "in a first-round tie where Cat should win in the second round" do
    let(:votes) {
      [
        [
          "Cat",
        ],
        %w[
          Rat
          Cat
        ],
      ]
    }

    it "provides a full text report showing the cat as the winner after eliminating the candidate with the fewest overall votes" do
      expect(runoff.report).to eq(
        <<~REPORT,
          Round 1

          Cat: 1/2 (50.0%)
          Rat: 1/2 (50.0%)

          No majority found.  Rat is eliminated.

          Round 2

          Cat: 2/2 (100.0%)

          Ballot complete.  Cat wins.
        REPORT
      )
    end
  end

  context "in a complete stalemate" do
    let(:votes) {
      [
        %w[
          Cat
          Rat
          Dog
        ],
        %w[
          Rat
          Dog
          Cat
        ],
        %w[
          Dog
          Cat
          Rat
        ],
      ]
    }

    it "calls for a new vote" do
      expect(runoff.report).to eq(
        <<~REPORT,
          Round 1

          Cat: 1/3 (33.33%)
          Dog: 1/3 (33.33%)
          Rat: 1/3 (33.33%)

          No majority found.  Cat, Dog and Rat are eliminated.

          All candidates have been eliminated.  Please call a new vote.
        REPORT
      )
    end
  end
end
