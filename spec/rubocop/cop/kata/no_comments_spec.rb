# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Kata::NoComments, :config) do
  include TabledCop

  let(:ruby_version) { 3.4 }

  it "flags a comment inside a method body" do
    expect_offense(<<~RUBY)
      def total
        # add up the lines
        ^^^^^^^^^^^^^^^^^^ Say it in the code: rename it, extract it, or name the constant.
        lines.sum
      end
    RUBY
    expect_correction(<<~RUBY)
      def total
        lines.sum
      end
    RUBY
  end

  it "flags a trailing comment, and takes the space before it" do
    expect_offense(<<~RUBY)
      total = lines.sum # only the billable ones
                        ^^^^^^^^^^^^^^^^^^^^^^^^ Say it in the code: rename it, extract it, or name the constant.
    RUBY
    expect_correction(<<~RUBY)
      total = lines.sum
    RUBY
  end

  # rails: 51,198 offenses, one per line of each block.
  it "flags a multi-line block once, and removes every line of it" do
    expect_offense(<<~RUBY)
      # First line.
      ^^^^^^^^^^^^^ Say it in the code: rename it, extract it, or name the constant.
      # Second line.
      def total = lines.sum
    RUBY
    expect_correction(<<~RUBY)
      def total = lines.sum
    RUBY
  end

  it "counts trailing comments on neighbouring lines one by one, apart from a block" do
    expect_offense(<<~RUBY)
      # Above.
      ^^^^^^^^ Say it in the code: rename it, extract it, or name the constant.
      total = 1 # first
                ^^^^^^^ Say it in the code: rename it, extract it, or name the constant.
      count = 2 # second
                ^^^^^^^^ Say it in the code: rename it, extract it, or name the constant.
    RUBY
  end

  it "flags the prose of a block around a directive it keeps" do
    expect_offense(<<~RUBY)
      def total
        # Before.
        ^^^^^^^^^ Say it in the code: rename it, extract it, or name the constant.
        # rubocop:disable Metrics/AbcSize
        # After.
        lines.sum
      end
    RUBY
    expect_correction(<<~RUBY)
      def total
        # rubocop:disable Metrics/AbcSize
        lines.sum
      end
    RUBY
  end

  it "flags an annotation, which is prose with a badge on" do
    expect_offense(<<~RUBY)
      # TODO: settle credits against the original invoice
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Say it in the code: rename it, extract it, or name the constant.
      def total = lines.sum
    RUBY
  end

  it "keeps magic comments and machine directives" do
    expect_no_offenses(<<~RUBY)
      #!/usr/bin/env ruby
      # frozen_string_literal: true
      # rubocop:disable Metrics/AbcSize
      # typed: strict
      # :nocov:
      def total = lines.sum
      # :nocov:
      # rubocop:enable Metrics/AbcSize
    RUBY
  end

  it "keeps a magic comment in any case, with dashes or underscores, as Ruby reads it" do
    expect_no_offenses(<<~RUBY)
      # frozen-string-literal: true
      # Shareable-Constant-Value: literal
      # WARN_INDENT: false
      # warn-past-scope: true
      # rbs-inline: enabled
      # frozen_string_literal : true
      TABLE = { a: [1] }
    RUBY
  end

  it "flags prose that only mentions a magic word" do
    expect_offense(<<~RUBY)
      # frozen string literals are fast
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Say it in the code: rename it, extract it, or name the constant.
      TABLE = { a: [1] }
    RUBY
  end

  it "keeps the directives RDoc and YARD read" do
    expect_no_offenses(<<~RUBY)
      # :stopdoc:
      def total = lines.sum #:nodoc:
      # :startdoc:
      # :call-seq:
      # @!method count
      # @!attribute [r] name
      def name = "x" # :nodoc:
    RUBY
  end

  context "with documentation priced, for an application" do
    let(:cop_config) { { "AllowDocumentation" => false } }

    it "flags a docblock above a class, and removes the line" do
      expect_offense(<<~RUBY)
        # Why this class exists.
        ^^^^^^^^^^^^^^^^^^^^^^^^ Say it in the code: rename it, extract it, or name the constant.
        class Invoice
        end
      RUBY
      expect_correction(<<~RUBY)
        class Invoice
        end
      RUBY
    end

    it "flags YARD tags, which are prose for a reader" do
      expect_offense(<<~RUBY)
        # @return [Integer]
        ^^^^^^^^^^^^^^^^^^^ Say it in the code: rename it, extract it, or name the constant.
        def total = lines.sum
      RUBY
    end
  end

  it "keeps the editor modelines Ruby and editors read the encoding from" do
    expect_no_offenses(<<~RUBY)
      # -*- coding: binary -*-
      # vim: set fileencoding=ascii-8bit :
      # vim:ts=2:sw=2
      # -*- mode: ruby -*-
      def total = lines.sum
    RUBY
  end

  it "flags prose that merely starts like a modeline" do
    expect_offense(<<~RUBY)
      # ex: the second total
      ^^^^^^^^^^^^^^^^^^^^^^ Say it in the code: rename it, extract it, or name the constant.
      def total = lines.sum
    RUBY
  end

  it "keeps the directives type checkers, linters and mutation testers read" do
    expect_no_offenses(<<~RUBY)
      # rbs_inline: enabled
      # @type var sum: Integer
      # @rbs lines: Array[Integer]
      #: (Array[Integer]) -> Integer
      # standard:disable Style/GlobalVars
      # steep:ignore
      # :reek:FeatureEnvy
      # kimera:disable-next-line: the flush is redundant on a sync pipe
      # hashira:disable-next-line feature_envy -- formats another object's numbers by design
      # language=SQL
      # noinspection RubyResolve
      def total(lines) = lines.sum
    RUBY
  end

  it "keeps a block that cites what the code cannot: a URL, an issue, an RFC, a CVE" do
    expect_no_offenses(<<~RUBY)
      # Net::HTTP reuses a socket the server already closed.
      # See https://github.com/ruby/net-http/issues/42
      def close = nil

      # Rack drops a nil header (rack/rack#2049).
      HEADER = "x"
      # Kept for old clients, see #1342.
      LEGACY = true
      # RFC 7231 section 6.5.1 forbids it.
      STATUS = 400
      # Escape first: CVE-2023-27530 and GH-17.
      LIMIT = 1
    RUBY
  end

  it "flags a number sign that cites nothing" do
    expect_offense(<<~RUBY)
      # the total is item#3 of the row
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Say it in the code: rename it, extract it, or name the constant.
      def total = lines.sum
    RUBY
  end

  context "with citations priced" do
    let(:cop_config) { { "AllowCitations" => false } }

    it "flags a citing block too" do
      expect_offense(<<~RUBY)
        # See https://example.com
        ^^^^^^^^^^^^^^^^^^^^^^^^^ Say it in the code: rename it, extract it, or name the constant.
        def close = nil
      RUBY
    end
  end

  context "with a project's own directive pattern" do
    let(:cop_config) { { "AllowedPatterns" => ["\\A#\\s*brakeman:"] } }

    it "keeps the comments it matches" do
      expect_no_offenses(<<~RUBY)
        # brakeman:ignore SQL
        def close = nil
      RUBY
    end
  end

  context "with the shipped defaults" do
    let(:cop_config) { RuboCop::ConfigLoader.default_configuration.for_cop("Kata/NoComments") }

    it "keeps a YARD block whole" do
      expect_no_offenses(<<~RUBY)
        # Totals the billable lines.
        #
        # @return [Integer]
        def total = lines.sum
      RUBY
    end

    it "marks the correction unsafe, so rubocop -a never deletes what a comment said" do
      expect(cop_config["SafeAutoCorrect"]).to(be(false))
    end
  end

  context "with documentation allowed, for a gem that publishes its API" do
    let(:cop_config) { { "AllowDocumentation" => true } }

    # rails: RDoc and Markdown above public methods were priced as prose,
    # because only YARD tags marked a block as documentation.
    it "keeps a block of any markup directly above a public class, module or method" do
      expect_no_offenses(<<~RUBY)
        # Holds the lines of one invoice.
        class Invoice
          # Totals the +billable+ lines.
          def total = lines.sum

          # Builds an *empty* invoice.
          def self.blank = new([])

          # Raised when a line is negative.
          module Errors
          end

          protected

          public

          # Counts the lines, back in public.
          def size = lines.size

          # Totals the credits.
          memoize def credits = []

          class << self
            # Parses an invoice from CSV.
            def parse(text) = new(text.lines)
          end
        end
      RUBY
    end

    it "flags a block above a private or protected method, inside a body, or apart by a blank line" do
      expect_offense(<<~RUBY)
        # Loose.
        ^^^^^^^^ Say it in the code: rename it, extract it, or name the constant.

        class Invoice
          def total
            # Adds them up.
            ^^^^^^^^^^^^^^^ Say it in the code: rename it, extract it, or name the constant.
            lines.sum
          end

          # Hidden at once.
          ^^^^^^^^^^^^^^^^^ Say it in the code: rename it, extract it, or name the constant.
          private def refunds = []

          # Fresh per call.
          ^^^^^^^^^^^^^^^^^ Say it in the code: rename it, extract it, or name the constant.
          private_class_method def self.blank = new

          private

          # Kept for the importer.
          ^^^^^^^^^^^^^^^^^^^^^^^^ Say it in the code: rename it, extract it, or name the constant.
          def lines = []

          class << self
            private

            # Parses one row.
            ^^^^^^^^^^^^^^^^^ Say it in the code: rename it, extract it, or name the constant.
            def row(text) = text
          end
        end
      RUBY
    end

    it "flags a block above a top-level method, which is private to Object" do
      expect_offense(<<~RUBY)
        # Runs the import.
        ^^^^^^^^^^^^^^^^^^ Say it in the code: rename it, extract it, or name the constant.
        def import = 1
        # Prints the totals.
        ^^^^^^^^^^^^^^^^^^^^ Say it in the code: rename it, extract it, or name the constant.
        def report = 2
      RUBY
    end

    it "flags a trailing comment on the line above a public method" do
      expect_offense(<<~RUBY)
        class Invoice
          attr_reader :lines # the lines
                             ^^^^^^^^^^^ Say it in the code: rename it, extract it, or name the constant.
          def total = lines.sum
        end
      RUBY
    end

    it "keeps a block that carries a YARD tag whole, wherever it stands, and only that block" do
      expect_offense(<<~RUBY)
        # Totals the billable lines.
        #
        # @param lines [Array<Line>] the invoice lines
        # @return [Integer]
        def total(lines) = lines.sum
        # Totals the refunds.
        ^^^^^^^^^^^^^^^^^^^^^ Say it in the code: rename it, extract it, or name the constant.

        # @api private
        def refunds = []
        # reversed below
        ^^^^^^^^^^^^^^^^ Say it in the code: rename it, extract it, or name the constant.
      RUBY
    end
  end

  it "keeps a licence header whole, prose lines and all — deleting one breaches the licence" do
    expect_no_offenses(<<~RUBY)
      # frozen_string_literal: true
      #
      # Copyright (c) 2019 Someone Else
      #
      # Permission is hereby granted, free of charge, to any person obtaining a copy
      # of this software and associated documentation files (the "Software"), to deal
      # in the Software without restriction.
      def total = lines.sum
    RUBY
  end

  it "keeps an SPDX identifier and a notice below the header" do
    expect_no_offenses(<<~RUBY)
      # SPDX-License-Identifier: Apache-2.0
      class Invoice
        # Copyright (c) 2019 Someone Else
        def total = lines.sum
      end
    RUBY
  end

  it "flags a header block that carries no notice, so the cop keeps its teeth" do
    expect_offense(<<~RUBY)
      # Why this file exists.
      ^^^^^^^^^^^^^^^^^^^^^^^ Say it in the code: rename it, extract it, or name the constant.
      # And what it does.
      def total = lines.sum
    RUBY
    expect_correction(<<~RUBY)
      def total = lines.sum
    RUBY
  end

  it "flags a trailing comment on the first line of code under a notice header" do
    expect_offense(<<~RUBY)
      # Copyright (c) 2019 Someone Else
      total = lines.sum # only the billable ones
                        ^^^^^^^^^^^^^^^^^^^^^^^^ Say it in the code: rename it, extract it, or name the constant.
    RUBY
  end

  it "flags a body comment in a file whose header carries a notice" do
    expect_offense(<<~RUBY)
      # Copyright (c) 2019 Someone Else
      def total = lines.sum
      # Why the total matters.
      ^^^^^^^^^^^^^^^^^^^^^^^^ Say it in the code: rename it, extract it, or name the constant.
    RUBY
  end

  it "flags a file that holds nothing but a comment" do
    expect_offense(<<~RUBY)
      # Nothing here yet.
      ^^^^^^^^^^^^^^^^^^^ Say it in the code: rename it, extract it, or name the constant.
    RUBY
  end

  it "removes a last-line comment that has no newline after it" do
    expect(autocorrect("total = lines.sum\n# the end")).to(eq("total = lines.sum\n"))
  end
end
