# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Kata::NoComments, :config) do
  include TabledCop

  let(:ruby_version) { 3.4 }

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

  it "flags every line of a multi-line block" do
    expect_offense(<<~RUBY)
      # First line.
      ^^^^^^^^^^^^^ Say it in the code: rename it, extract it, or name the constant.
      # Second line.
      ^^^^^^^^^^^^^^ Say it in the code: rename it, extract it, or name the constant.
      def total = lines.sum
    RUBY
    expect_correction(<<~RUBY)
      def total = lines.sum
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

  it "flags YARD tags, which are prose for a reader" do
    expect_offense(<<~RUBY)
      # @return [Integer]
      ^^^^^^^^^^^^^^^^^^^ Say it in the code: rename it, extract it, or name the constant.
      def total = lines.sum
    RUBY
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
      ^^^^^^^^^^^^^^^^^^^ Say it in the code: rename it, extract it, or name the constant.
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
