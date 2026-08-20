# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Kata::AgentNoun, :config) do
  let(:cop_config) { { "AllowedNames" => %w[Error] } }

  it "flags -er and -or class names, however nested" do
    expect_offense(<<~RUBY)
      class App::Search::Fetcher
            ^^^^^^^^^^^^^^^^^^^^ `Fetcher` names a doer; name the class for the thing it is, not the work it does.
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

  it "exempts every name ending in an allowed one, so Error covers UsageError" do
    expect_no_offenses(<<~RUBY)
      class UsageError
      end
      class Kimera::DiffError
      end
    RUBY
  end

  it "derives the agent word of a compound and keeps the rest" do
    expect_offense(<<~RUBY)
      class EvidenceValidator
            ^^^^^^^^^^^^^^^^^ `EvidenceValidator` names a doer; name the class for the thing it is, not the work it does. Try `EvidenceValidation`.
      end
      class RouteSelector
            ^^^^^^^^^^^^^ `RouteSelector` names a doer; name the class for the thing it is, not the work it does. Try `RouteSelection`.
      end
    RUBY
  end

  it "preserves acronym segments in a compound suggestion" do
    expect_offense(<<~RUBY)
      class PaymentJSONValidator
            ^^^^^^^^^^^^^^^^^^^^ `PaymentJSONValidator` names a doer; name the class for the thing it is, not the work it does. Try `PaymentJSONValidation`.
      end
    RUBY
  end

  it "never truncates a compound to a name its siblings would share" do
    expect_offense(<<~RUBY)
      class EvidencePoller
            ^^^^^^^^^^^^^^ `EvidencePoller` names a doer; name the class for the thing it is, not the work it does.
      end
      class EvidenceWaiter
            ^^^^^^^^^^^^^^ `EvidenceWaiter` names a doer; name the class for the thing it is, not the work it does.
      end
      class SandboxReaper
            ^^^^^^^^^^^^^ `SandboxReaper` names a doer; name the class for the thing it is, not the work it does.
      end
    RUBY
  end

  it "suggests the noun a regular agent suffix derives from" do
    expect_offense(<<~RUBY)
      class Selector
            ^^^^^^^^ `Selector` names a doer; name the class for the thing it is, not the work it does. Try `Selection`.
      end
      class Validator
            ^^^^^^^^^ `Validator` names a doer; name the class for the thing it is, not the work it does. Try `Validation`.
      end
      class Synthesizer
            ^^^^^^^^^^^ `Synthesizer` names a doer; name the class for the thing it is, not the work it does. Try `Synthesis`.
      end
    RUBY
  end

  it "stays quiet about a name it cannot derive or confirm in the dictionary" do
    expect_offense(<<~RUBY)
      class Chunker
            ^^^^^^^ `Chunker` names a doer; name the class for the thing it is, not the work it does.
      end
      class Vector
            ^^^^^^ `Vector` names a doer; name the class for the thing it is, not the work it does.
      end
      class Blorbinator
            ^^^^^^^^^^^ `Blorbinator` names a doer; name the class for the thing it is, not the work it does.
      end
    RUBY
  end

  it "never suggests a name the cop would reject in turn" do
    expect_offense(<<~RUBY)
      class WorkerRunner
            ^^^^^^^^^^^^ `WorkerRunner` names a doer; name the class for the thing it is, not the work it does.
      end
    RUBY
  end

  context "with the shipped defaults" do
    let(:cop_config) { RuboCop::ConfigLoader.default_configuration.for_cop("Kata/AgentNoun") }

    it "exempts the suffixes a framework resolves a class by" do
      expect_no_offenses(<<~RUBY)
        class AccountsController
        end
        class InviteMailer
        end
        class AccountSerializer
        end
      RUBY
    end
  end
end
