# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Kata::AgentNoun, :config) do
  let(:cop_config) { { "AllowedNames" => %w[Error] } }

  it "flags -er and -or class names, however nested" do
    expect_offense(<<~RUBY)
      class App::Search::Indexer
            ^^^^^^^^^^^^^^^^^^^^ `Indexer` names a doer; name the class for the thing it is, not the work it does.
      end
      module Resolver
             ^^^^^^^^ `Resolver` names a doer; name the class for the thing it is, not the work it does.
      end
    RUBY
  end

  it "allows names that merely end in the letters" do
    expect_no_offenses(<<~RUBY)
      class Invoice::Error
      end
      class Graph
      end
    RUBY
  end
end
