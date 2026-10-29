# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Kata::GoodClassName, :config) do
  let(:cop_config) { { "AllowedNames" => %w[Error] } }

  it "flags -er and -or class names, however nested" do
    expect_offense(<<~RUBY)
      class App::Search::Fetcher
            ^^^^^^^^^^^^^^^^^^^^ `Fetcher` names a doer; name the class for the thing it is, not the work it does.
      end
    RUBY
  end

  # CocoaPods: `Installer` was flagged in each of the 54 files that reopen it
  # only to nest a class inside.
  it "judges a class where it is defined, not in each file that reopens it as a namespace" do
    expect_offense(<<~RUBY)
      class Installer
        class Analyzer
              ^^^^^^^^ `Analyzer` names a doer; name the class for the thing it is, not the work it does.
        end
        module Helpers
        end
      end
      class Installer
            ^^^^^^^^^ `Installer` names a doer; name the class for the thing it is, not the work it does.
        def install; end
      end
      class Installer < Base
        class Context
        end
      end
      class Installer
            ^^^^^^^^^ `Installer` names a doer; name the class for the thing it is, not the work it does.
      end
    RUBY
  end

  it "leaves modules to Kata/GoodModuleName" do
    expect_no_offenses(<<~RUBY)
      module Resolver
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
      class EvidenceAggregator
            ^^^^^^^^^^^^^^^^^^ `EvidenceAggregator` names a doer; name the class for the thing it is, not the work it does. Try `EvidenceAggregation`.
      end
      class RouteSelector
            ^^^^^^^^^^^^^ `RouteSelector` names a doer; name the class for the thing it is, not the work it does. Try `RouteSelection`.
      end
    RUBY
  end

  it "preserves acronym segments in a compound suggestion" do
    expect_offense(<<~RUBY)
      class PaymentJSONAggregator
            ^^^^^^^^^^^^^^^^^^^^^ `PaymentJSONAggregator` names a doer; name the class for the thing it is, not the work it does. Try `PaymentJSONAggregation`.
      end
    RUBY
  end

  it "never truncates a compound to a name its siblings would share" do
    expect_offense(<<~RUBY)
      class EvidencePoller
            ^^^^^^^^^^^^^^ `EvidencePoller` names a doer; name the class for the thing it is, not the work it does.
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

  context "with banned names" do
    let(:cop_config) { { "BannedNames" => %w[Util Service Data] } }

    it "flags junk-drawer names, whole or as a trailing segment" do
      expect_offense(<<~RUBY)
        class Util
              ^^^^ `Util` is a junk drawer; it hides the concept the code is missing.
        end
        class InvoiceService
              ^^^^^^^^^^^^^^ `InvoiceService` is a junk drawer; it hides the concept the code is missing.
        end
        class UserData
              ^^^^^^^^ `UserData` is a junk drawer; it hides the concept the code is missing.
        end
      RUBY
    end

    it "allows names that merely contain the word" do
      expect_no_offenses(<<~RUBY)
        class Utility
        end
      RUBY
    end
  end

  context "with crowded names" do
    it "flags a name packing more concepts than MaxWords" do
      expect_offense(<<~RUBY)
        class CustomerOrderPayment
              ^^^^^^^^^^^^^^^^^^^^ `CustomerOrderPayment` packs 3 concepts into one name; a class names one object that exists in the model — or, if `CustomerOrderPayment` reads as one concept here, add it to `Terms`.
        end
      RUBY
    end

    it "allows a two-segment name: compound syntax is not the smell" do
      expect_no_offenses(<<~RUBY)
        class CreditCard
        end
        class PostalCode
        end
      RUBY
    end

    context "with a reviewed Term" do
      let(:cop_config) { { "Terms" => %w[CustomerOrderPayment] } }

      it "exempts the Term exactly" do
        expect_no_offenses(<<~RUBY)
          class CustomerOrderPayment
          end
        RUBY
      end
    end
  end

  context "with a contract superclass" do
    let(:cop_config) { { "ContractSuperclasses" => %w[RuboCop::Cop::Base] } }

    it "leaves a class a framework resolves by its name, written in full or found lexically" do
      expect_no_offenses(<<~RUBY)
        class TokenCrowdedCheckerName < RuboCop::Cop::Base
        end
        module RuboCop
          module Cop
            module Lsp
              class UseLanguageServerAliasesNow < Base
              end
            end
          end
        end
      RUBY
    end

    it "still judges a class whose Base is some other library's" do
      expect_offense(<<~RUBY)
        module Billing
          class InvoiceProcessor < Base
                ^^^^^^^^^^^^^^^^ `InvoiceProcessor` names a doer; name the class for the thing it is, not the work it does.
          end
        end
      RUBY
    end
  end

  context "with the shipped defaults" do
    let(:cop_config) { RuboCop::ConfigLoader.default_configuration.for_cop("Kata/GoodClassName") }

    it "exempts thing-words that merely end in -er/-or" do
      expect_no_offenses(<<~RUBY)
        class User
        end
        class Order
        end
        class Customer
        end
        class Monitor
        end
        class PowerUser
        end
      RUBY
    end

    it "reads a persisted record as the thing it records, whatever its name" do
      expect_offense(<<~RUBY)
        class Manufacturer < ApplicationRecord
        end
        class Teacher < ActiveRecord::Base
        end
        class Teacher < Person
              ^^^^^^^ `Teacher` names a doer; name the class for the thing it is, not the work it does.
        end
        class OrderService < ApplicationRecord
              ^^^^^^^^^^^^ `OrderService` is a junk drawer; it hides the concept the code is missing.
        end
      RUBY
    end

    it "still flags genuine doers" do
      expect_offense(<<~RUBY)
        class RateLimiter
              ^^^^^^^^^^^ `RateLimiter` names a doer; name the class for the thing it is, not the work it does.
        end
        class CircuitBreaker
              ^^^^^^^^^^^^^^ `CircuitBreaker` names a doer; name the class for the thing it is, not the work it does.
        end
      RUBY
    end

    it "exempts established technical compounds, and only those" do
      expect_offense(<<~RUBY)
        class RedBlackTree
        end
        class AbstractSyntaxTree
        end
        class TimeWithZone
        end
        class CustomerOrderPayment
              ^^^^^^^^^^^^^^^^^^^^ `CustomerOrderPayment` packs 3 concepts into one name; a class names one object that exists in the model — or, if `CustomerOrderPayment` reads as one concept here, add it to `Terms`.
        end
      RUBY
    end

    it "exempts the suffixes a framework resolves a class by" do
      expect_no_offenses(<<~RUBY)
        class AccountsController
        end
        class InviteMailer
        end
        class AccountSerializer
        end
        class WebHookPolicy
        end
        class OpenGraphComponent
        end
        class InstallGenerator
        end
        class RoomChannel
        end
        class EmailValidator < ActiveModel::EachValidator
        end
        class InvoiceDigestJob < ApplicationJob
        end
        class Maintenance::SpamCleanupTask < MaintenanceTasks::Task
        end
      RUBY
    end

    it "judges the subject a framework suffix leaves, not the suffix" do
      expect_offense(<<~RUBY)
        class RubygemTrustedPublishersController < ApplicationController
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ `RubygemTrustedPublishers` packs 3 concepts into one name; a class names one object that exists in the model — or, if `RubygemTrustedPublishers` reads as one concept here, add it to `Terms`.
        end
        class ReportBuilderJob < ApplicationJob
              ^^^^^^^^^^^^^^^^ `ReportBuilder` names a doer; name the class for the thing it is, not the work it does.
        end
        class UsersControllerTest < ActionDispatch::IntegrationTest
        end
      RUBY
    end

    context "with the module contracts Kata/GoodModuleName ships" do
      let(:other_cops) do
        { "Kata/GoodModuleName" => RuboCop::ConfigLoader.default_configuration.for_cop("Kata/GoodModuleName") }
      end

      it "judges a helper's test by the helper's subject, as Kata/GoodModuleName judges the helper" do
        expect_no_offenses(<<~RUBY)
          class MessagesHelperTest < ActionView::TestCase
          end
          class RichTextHelperTest < ActionView::TestCase
          end
        RUBY
      end

      it "keeps a class that ends in a module's contract a doer when no test names it" do
        expect_offense(<<~RUBY)
          class MessagesHelper
                ^^^^^^^^^^^^^^ `MessagesHelper` names a doer; name the class for the thing it is, not the work it does.
          end
        RUBY
      end
    end

    it "keeps a bare suffix a doer, since no framework resolves it" do
      expect_offense(<<~RUBY)
        class Controller
              ^^^^^^^^^^ `Controller` names a doer; name the class for the thing it is, not the work it does.
        end
      RUBY
    end

    it "lets a class inherit the agent word of the superclass that chose it" do
      expect_no_offenses(<<~RUBY)
        class ActionHandler < Avo::Actions::ActionHandler
        end
        class AuditLogger < ::Logger
        end
        class JsonFormatter < Logger::Formatter
        end
      RUBY
    end

    it "judges a test as its subject, heir to the framework class that chose the agent word" do
      expect_no_offenses(<<~RUBY)
        class Campfire::ScrubbingFormatterTest < ActiveSupport::TestCase
        end
        class AuditLoggerTest < ActiveSupport::TestCase
        end
        class RequestSubscriberSpec
        end
      RUBY
    end

    it "still flags the test of a doer no framework class names, or the class itself" do
      expect_offense(<<~RUBY)
        class PaymentProcessorTest < ActiveSupport::TestCase
              ^^^^^^^^^^^^^^^^^^^^ `PaymentProcessor` names a doer; name the class for the thing it is, not the work it does.
        end
        class ScrubbingFormatter
              ^^^^^^^^^^^^^^^^^^ `ScrubbingFormatter` names a doer; name the class for the thing it is, not the work it does.
        end
      RUBY
    end

    it "judges the test of a contract by the contract's subject, whatever the contract inherits" do
      expect_offense(<<~RUBY)
        class ScrubbingFormatterJobTest < ActiveJob::TestCase
              ^^^^^^^^^^^^^^^^^^^^^^^^^ `ScrubbingFormatter` names a doer; name the class for the thing it is, not the work it does.
        end
      RUBY
    end

    it "still flags a doer whose superclass names something else" do
      expect_offense(<<~RUBY)
        class AuditLogger < Base
              ^^^^^^^^^^^ `AuditLogger` names a doer; name the class for the thing it is, not the work it does.
        end
        class Handler < Struct.new(:name)
              ^^^^^^^ `Handler` names a doer; name the class for the thing it is, not the work it does.
        end
      RUBY
    end

    it "reads a thing-word as a thing whatever its letters, so no list holds it" do
      expect_no_offenses(<<~RUBY)
        class Header
        end
        class Number
        end
        class Layer
        end
        class Letter
        end
        class Corner
        end
        class Matter
        end
        class Folder
        end
        class Customer
        end
      RUBY
    end

    it "keeps the domain roles a model represents" do
      expect_no_offenses(<<~RUBY)
        class User
        end
        class Owner
        end
        class Billing::Vendor
        end
      RUBY
    end

    it "judges a test or a preview by the name of its subject" do
      expect_offense(<<~RUBY)
        class UsersControllerTest < ActionDispatch::IntegrationTest
        end
        class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
        end
        class InvoiceSpec
        end
        class ButtonComponentPreview < ViewComponent::Preview
        end
        class Test
        end
        class RateLimiterTest
              ^^^^^^^^^^^^^^^ `RateLimiter` names a doer; name the class for the thing it is, not the work it does.
        end
      RUBY
    end
  end

  it "does not read a known word as a doer unless its stem is a verb" do
    expect_offense(<<~RUBY)
      class Volunteer
      end
      class Filter
      end
      class Partner
      end
      class Parser
            ^^^^^^ `Parser` names a doer; name the class for the thing it is, not the work it does.
      end
      class Supervisor
            ^^^^^^^^^^ `Supervisor` names a doer; name the class for the thing it is, not the work it does. Try `Supervision`.
      end
      class Notifier
            ^^^^^^^^ `Notifier` names a doer; name the class for the thing it is, not the work it does.
      end
      class Mapper
            ^^^^^^ `Mapper` names a doer; name the class for the thing it is, not the work it does.
      end
      class Processor
            ^^^^^^^^^ `Processor` names a doer; name the class for the thing it is, not the work it does.
      end
    RUBY
  end

  context "with a project's framework superclasses" do
    let(:cop_config) { { "Suffixes" => %w[Test], "FrameworkSuperclasses" => %w[Avo::Actions::ActionHandler] } }

    it "judges a test by the agent word the listed superclass hands its subject" do
      expect_offense(<<~RUBY)
        class Avo::ActionHandlerTest
        end
        class ActionHandler
              ^^^^^^^^^^^^^ `ActionHandler` names a doer; name the class for the thing it is, not the work it does.
        end
        class ScrubbingFormatterTest
              ^^^^^^^^^^^^^^^^^^^^^^ `ScrubbingFormatter` names a doer; name the class for the thing it is, not the work it does.
        end
      RUBY
    end
  end

  context "when reading the doer data" do
    it "takes WordNet's word that an -ar noun is an agent" do
      expect_offense(<<~RUBY)
        class Liar
              ^^^^ `Liar` names a doer; name the class for the thing it is, not the work it does.
        end
      RUBY
    end

    it "reads a verb-shaped stem, or a verb behind a prefix, as a doer WordNet does not list" do
      expect_offense(<<~RUBY)
        class Hypervisor
              ^^^^^^^^^^ `Hypervisor` names a doer; name the class for the thing it is, not the work it does.
        end
        class Uninstaller
              ^^^^^^^^^^^ `Uninstaller` names a doer; name the class for the thing it is, not the work it does.
        end
      RUBY
    end

    it "reads a coinage as a doer only when its stem is a verb, as the configuration says" do
      expect_offense(<<~RUBY)
        class Differ
        end
        class Zorper
        end
        class Instapaper
        end
        class Kickstarter
        end
        class Chunker
              ^^^^^^^ `Chunker` names a doer; name the class for the thing it is, not the work it does.
        end
        class Upserter
              ^^^^^^^^ `Upserter` names a doer; name the class for the thing it is, not the work it does.
        end
      RUBY
    end
  end

  # kimera's RSpecSuite: rubocop-rspec's transform spells `RSpec` as one word.
  context "with brands spelled as one word" do
    let(:other_cops) do
      transform = { "RSpec" => "rspec", "RuboCop" => "rubocop", "SuiteRSpecTable" => "suite_rspec_table" }
      { "RSpec/SpecFilePathFormat" => { "CustomTransform" => transform } }
    end

    # The project constants #19's transform adds (`SuiteRSpecTable: suite_rspec_table`) are paths, not words.
    it "counts a brand as one concept, and still reads the doer after it" do
      expect_offense(<<~RUBY)
        class RSpecSuite
        end
        class RuboCopSheet
        end
        class RSpecFetcher
              ^^^^^^^^^^^^ `RSpecFetcher` names a doer; name the class for the thing it is, not the work it does.
        end
        class SuiteRSpecTable
              ^^^^^^^^^^^^^^^ `SuiteRSpecTable` packs 3 concepts into one name; a class names one object that exists in the model — or, if `SuiteRSpecTable` reads as one concept here, add it to `Terms`.
        end
      RUBY
    end
  end

  context "with the project's root constants" do
    let(:cop_config) { { "Roots" => %w[Rubocop::Kata::Planner] } }

    it "passes the root class, which names the gem" do
      expect_no_offenses(<<~RUBY)
        module RuboCop
          module Kata
            class Planner
              def stage; end
            end
          end
        end
      RUBY
    end
  end

  context "with CheckContracts, the strict profile's reading of a contract suffix" do
    include ProjectFiles

    let(:cop_config) do
      RuboCop::ConfigLoader.default_configuration.for_cop("Kata/GoodClassName").merge("CheckContracts" => true)
    end
    let(:setting) { { "Kata/GoodClassName" => cop_config } }
    let(:posed) do
      "names a doer: `%s` is a framework's word only where a superclass or mixin takes part in that contract, " \
        "and none does here; name the class for the thing it is, not the work it does."
    end

    # V1 P01: `InvoiceGenerator` passed because `Generator` is a contract suffix.
    it "reads an agent-word suffix as a doer where no superclass or mixin takes part in its contract" do
      expect_offense(<<~RUBY)
        class InvoiceGenerator
              ^^^^^^^^^^^^^^^^ `InvoiceGenerator` #{format(posed, "Generator")}
        end
        class EmailValidator
              ^^^^^^^^^^^^^^ `EmailValidator` #{format(posed, "Validator")}
        end
        class AccountSerializer < Struct.new(:account)
              ^^^^^^^^^^^^^^^^^ `AccountSerializer` #{format(posed, "Serializer")}
        end
        class UserDecorator < SimpleDelegator
              ^^^^^^^^^^^^^ `UserDecorator` #{format(posed, "Decorator")}
        end
        module Billing
          class StripeAdapter < Base
                ^^^^^^^^^^^^^ `StripeAdapter` #{format(posed, "Adapter")}
          end
        end
      RUBY
    end

    it "passes a class whose superclass or mixin names the contract, written or found lexically" do
      expect_no_offenses(<<~RUBY)
        class EmailValidator < ActiveModel::EachValidator
        end
        class InstallGenerator < ::Rails::Generators::Base
        end
        class AccountsController < ApplicationController
        end
        class InviteMailer < ActionMailer::Base
        end
        class MovieSerializer
          include JSONAPI::Serializer
        end
        class UserDecorator < Draper::Decorator
        end
        class InvoiceGenerator < BaseGenerator
        end
        class UserMailer < Pay.parent_mailer.constantize
        end
        class ActiveRecord::ConnectionAdapters::OracleEnhancedAdapter
        end
        module StrongMigrations
          module Adapters
            class MysqlAdapter
            end
          end
        end
        module Rails
          module Generators
            class ScaffoldGenerator < NamedBase
            end
          end
        end
      RUBY
    end

    it "leaves a bare contract word and a persisted record to the shipped reading" do
      expect_offense(<<~RUBY)
        class Generator
        end
        class Validator
              ^^^^^^^^^ `Validator` names a doer; name the class for the thing it is, not the work it does. Try `Validation`.
        end
        class InvoiceGenerator < ApplicationRecord
        end
        class ReportGenerator < GeneratorBase
        end
      RUBY
    end

    it "leaves a suffix that is no agent word, and a test or a preview, to the subject's reading" do
      expect_no_offenses(<<~RUBY)
        class InvoiceDigestJob
        end
        class WebHookPolicy
        end
        class RoomChannel
        end
        class UsersControllerTest < ActionDispatch::IntegrationTest
        end
        class InvoiceGeneratorTest < Minitest::Test
        end
        class InviteMailerPreview < ActionMailer::Preview
        end
      RUBY
    end

    context "with a controller whose superclass is a library's" do
      let(:source) { "class Admin::PlacesController < InheritedResources::Base\nend\n" }

      # places-manager: `Admin::PlacesController < InheritedResources::Base`, a controller the router resolves.
      it "finds the contract in the folder the framework loads the class from" do
        path = "app/controllers/admin/places_controller.rb"
        expect(project_offenses({ path => source }, path)).to(be_empty)
      end

      it "reads the class as a doer in a folder no framework reads that word from" do
        path = "app/models/places_controller.rb"
        expect(project_offenses({ path => source }, path).size).to(eq(1))
      end
    end

    context "with the project's own superclass in another file" do
      let(:files) do
        {
          "lib/shop/scaffold.rb" => "module Shop\n  class Scaffold < Rails::Generators::Base\n  end\nend\n",
          "lib/shop/invoice_generator.rb" => "module Shop\n  class InvoiceGenerator < Scaffold\n  end\nend\n"
        }
      end

      it "finds the contract through that superclass" do
        expect(project_offenses(files, "lib/shop/invoice_generator.rb")).to(be_empty)
      end

      it "reads the class as a doer where the project does not hold that superclass" do
        lone = files.slice("lib/shop/invoice_generator.rb")
        expect(project_offenses(lone, "lib/shop/invoice_generator.rb").map(&:message))
          .to(eq(["`InvoiceGenerator` #{format(posed, "Generator")}"]))
      end
    end
  end
end
