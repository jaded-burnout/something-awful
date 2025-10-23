class InstantRunoff
  MAJORITY_THRESHOLD = 50 # percent

  def initialize(votes:)
    @votes = votes.reject { |v| v.nil? || v.empty? }
  end

  def report
    output = StringIO.new
    winner = nil
    round = 0

    until winner || @votes.empty?
      round += 1
      print_round_number(round, output)

      votes_per_candidate = tally_votes(@votes)
      print_individual_results(votes_per_candidate, output)

      if (majority_winner = find_winner_by_majority(votes_per_candidate, @votes.count))
        winner = majority_winner
      else
        @votes, eliminated_candidates = reassign_loser_votes(@votes, votes_per_candidate)
        candidate_sentence = [
          to_sentence(eliminated_candidates),
          pluralize("is", "are", eliminated_candidates.count),
        ].join(" ")

        output.puts "No majority found.  #{candidate_sentence} eliminated."
        output.puts
      end
    end

    if winner
      print_winner(winner, output)
    else
      output.puts "All candidates have been eliminated.  Please call a new vote."
    end

    output.rewind
    output.read
  end

private

  def find_winner_by_majority(votes_per_candidate, total_vote_count)
    highest_candidate, count = votes_per_candidate.max_by(&:last)

    if count && percentage(count, total_vote_count) > MAJORITY_THRESHOLD
      highest_candidate
    end
  end

  def reassign_loser_votes(votes, votes_per_candidate)
    candidates_with_lowest_vote = find_candidates_with_lowest_vote(votes_per_candidate)
    candidates_to_eliminate = if candidates_with_lowest_vote == votes_per_candidate.keys
      find_candidates_with_fewest_overall_votes(candidates_with_lowest_vote)
    else
      candidates_with_lowest_vote
    end

    reassigned_votes = votes.map { |vote_list|
      vote_list - candidates_to_eliminate
    }

    [reassigned_votes.reject { |v| v.nil? || v.empty? }, candidates_to_eliminate.sort]
  end

  def percentage(count, total)
    (count / total.to_f) * 100.0
  end

  def tally_votes(votes)
    votes_per_candidate = Hash.new(0)

    votes.each do |(voted_candidate, _rest)|
      if voted_candidate
        votes_per_candidate[voted_candidate] += 1
      end
    end

    votes_per_candidate
  end

  def find_candidates_with_lowest_vote(votes_per_candidate)
    lowest_vote_count = votes_per_candidate.map(&:last).min
    votes_per_candidate.each_with_object([]) { |(candidate, vote_count), array|
      array << candidate if vote_count == lowest_vote_count
    }
  end

  def find_candidates_with_fewest_overall_votes(candidates_with_lowest_vote)
    all_votes = @votes.flatten
    vote_subset = (all_votes - (all_votes - candidates_with_lowest_vote))

    votes_per_candidate = vote_subset.each_with_object(Hash.new(0)) do |candidate, hash|
      hash[candidate] += 1
    end

    find_candidates_with_lowest_vote(votes_per_candidate)
  end

  def print_individual_results(votes_per_candidate, output)
    votes_per_candidate
      .sort_by { |candidate, count| [-count, candidate] }
      .each do |candidate, count|
        output.puts "#{candidate}: #{count}/#{@votes.count} (#{percentage(count, @votes.count).round(2)}%)"
      end

    output.puts
  end

  def print_round_number(round_number, output)
    output.puts "Round #{round_number}"
    output.puts
  end

  def print_winner(winner, output)
    output.puts "Ballot complete.  #{winner} wins."
  end

  def to_sentence(strings)
    [strings[0..-2].join(", "), strings.last].reject { |s| s.nil? || s.empty? }.join(" and ")
  end

  def pluralize(singular, plural, count)
    count == 1 ? singular : plural
  end
end
