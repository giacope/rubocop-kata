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

  # nokogiri's `HTML5`: an acronym and its version are one concept.
  it "reads an acronym followed by digits as one concept" do
    expect_offense(<<~RUBY)
      module HTML5
      end
      module UTF8Input
      end
      module HTML5ParserOptions
             ^^^^^^^^^^^^^^^^^^ `HTML5ParserOptions` packs 3 concepts into one name; a module names one domain — or, if `HTML5ParserOptions` reads as one concept here, add it to `Terms`.
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

  it "does not read a known word as a doer unless its stem is a verb" do
    expect_offense(<<~RUBY)
      module Partner
      end
      module Handler
             ^^^^^^^ `Handler` names a doer; name the module for the thing it is, not the work it does.
      end
    RUBY
  end

  context "with the project's root constants" do
    let(:cop_config) { { "BannedNames" => %w[Core], "Roots" => %w[Faker Nanoc::Core] } }

    it "passes them, since they name the gem" do
      expect_no_offenses(<<~RUBY)
        module Faker
        end
        module Nanoc
          module Core
          end
        end
      RUBY
    end
  end

  # flipper: `module Flipper; module Services` opens the namespace around each class.
  context "with the project's files" do
    include ProjectFiles

    let(:setting) do
      named = { "OwnedPaths" => ["lib/**/*.rb"], "BannedNames" => %w[Services] }
      { "Kata/GoodModuleName" => named, "Kata" => { "Roots" => %w[Flipper] } }
    end
    let(:reopened) do
      {
        "lib/flipper/ui_services/actor.rb" => "module Flipper\n  module UiServices\n    class Actor; end\n  end\nend\n",
        "lib/flipper/ui_services/gate.rb" => "module Flipper\n  module UiServices\n    class Gate; end\n  end\nend\n",
        "lib/flipper/ui_services/many.rb" => "module Flipper\n  module UiServices\n    A = 1\n    B = 2\n  end\nend\n"
      }
    end

    it "judges a namespace once: in the file named for it, else where it holds the most" do
      named = reopened.merge("lib/flipper/ui_services.rb" => "module Flipper\n  module UiServices\n  end\nend\n")
      found = [reopened, named].map { |files| files.keys.map { project_offenses(files, it).size } }
      expect(found).to(eq([[0, 0, 1], [0, 0, 0, 1]]))
    end

    # sshkit: -a closed the blank lines around `module Formatter` after the project was read (R6B6-K2).
    it "finds a reopening by its place among the file's openings, not by the line the project read" do
      spaced = reopened.transform_values { it.gsub("\n  module", "\n\n  module").gsub("\n  end", "\n\n  end") }
      found = spaced.keys.map { project_offenses(spaced, it, reopened.fetch(it)).size }
      expect(found).to(eq([0, 0, 1]))
    end
  end
end
