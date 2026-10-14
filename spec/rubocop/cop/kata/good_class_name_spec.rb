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

    it "reads a coinage as a doer, and a known word whose stem is no verb as none" do
      expect_offense(<<~RUBY)
        class Differ
        end
        class Zorper
              ^^^^^^ `Zorper` names a doer; name the class for the thing it is, not the work it does.
        end
      RUBY
    end
  end
end
