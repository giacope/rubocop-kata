# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Kata::GoodModuleName, :config) do
  let(:cop_config) { { "BannedNames" => %w[Services Common Core Logic] } }

  it "flags layer buckets and vague shared namespaces, whole or trailing" do
    expect_offense(<<~RUBY)
      module Services
             ^^^^^^^^ `Services` names a layer or a junk drawer; a module names a domain vocabulary.
      end
      module App::Common
             ^^^^^^^^^^^ `Common` names a layer or a junk drawer; a module names a domain vocabulary.
      end
      module ApplicationServices
             ^^^^^^^^^^^^^^^^^^^ `ApplicationServices` names a layer or a junk drawer; a module names a domain vocabulary.
      end
      module BusinessLogic
             ^^^^^^^^^^^^^ `BusinessLogic` names a layer or a junk drawer; a module names a domain vocabulary.
      end
    RUBY
  end

  it "flags doer modules" do
    expect_offense(<<~RUBY)
      module Resolver
             ^^^^^^^^ `Resolver` names a doer; name the module for the thing it is, not the work it does.
      end
    RUBY
  end

  it "leaves classes to Kata/GoodClassName" do
    expect_no_offenses(<<~RUBY)
      class Fetcher
      end
    RUBY
  end

  it "allows domain vocabularies, compound or not" do
    expect_no_offenses(<<~RUBY)
      module Billing
      end
      module AccessControl
      end
    RUBY
  end

  it "flags a name packing more concepts than MaxWords" do
    expect_offense(<<~RUBY)
      module CustomerOrderBilling
             ^^^^^^^^^^^^^^^^^^^^ `CustomerOrderBilling` packs 3 concepts into one name; a module names one domain — or, if `CustomerOrderBilling` reads as one concept here, add it to `Terms`.
      end
    RUBY
  end

  context "with a reviewed Term" do
    let(:cop_config) { { "Terms" => %w[CustomerOrderBilling] } }

    it "exempts the Term exactly" do
      expect_no_offenses(<<~RUBY)
        module CustomerOrderBilling
        end
      RUBY
    end
  end

  context "with the shipped defaults" do
    let(:cop_config) { RuboCop::ConfigLoader.default_configuration.for_cop("Kata/GoodModuleName") }

    it "exempts the framework namespaces a reopen must spell exactly" do
      expect_no_offenses(<<~RUBY)
        module ActionController
        end
        module ActionMailer
        end
      RUBY
    end

    it "exempts Error modules and names ending in Error" do
      expect_no_offenses(<<~RUBY)
        module Error
        end
        module UsageError
        end
      RUBY
    end

    it "flags the layer names teams reach for" do
      expect_offense(<<~RUBY)
        module Helpers
               ^^^^^^^ `Helpers` names a layer or a junk drawer; a module names a domain vocabulary.
        end
        module Shared
               ^^^^^^ `Shared` names a layer or a junk drawer; a module names a domain vocabulary.
        end
        module Core
               ^^^^ `Core` names a layer or a junk drawer; a module names a domain vocabulary.
        end
      RUBY
    end
  end
end
