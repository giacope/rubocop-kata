# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Kata::NoEmptyLinesInBlocks, :config) do
  let(:ruby_version) { 3.4 }

  it "flags and removes a blank line in a block, once even when blocks nest" do
    expect_offense(<<~RUBY)
      items.each do |item|
        list.each do |entry|
          entry.call

      ^{} Empty line inside block body is not allowed
          item.call
        end
      end
    RUBY
    expect_correction(<<~RUBY)
      items.each do |item|
        list.each do |entry|
          entry.call
          item.call
        end
      end
    RUBY
  end

  it "flags blank lines in conditionals, loops, case and begin" do
    expect_offense(<<~RUBY)
      if ready
        start

      ^{} Empty line inside block body is not allowed
        finish
      end
      while running
        step

      ^{} Empty line inside block body is not allowed
        rest
      end
      until done
        step

      ^{} Empty line inside block body is not allowed
        rest
      end
      for item in items
        step

      ^{} Empty line inside block body is not allowed
        rest
      end
      case kind
      when :a
        step

      ^{} Empty line inside block body is not allowed
        rest
      end
      case value
      in Integer
        step

      ^{} Empty line inside block body is not allowed
        rest
      end
      begin
        step

      ^{} Empty line inside block body is not allowed
        rest
      end
      items.map { _1

      ^{} Empty line inside block body is not allowed
      }
    RUBY
  end

  it "keeps heredoc text inside a block" do
    expect_no_offenses(<<~RUBY)
      if type
        lines << <<~MD
          `\#{type}`

          ----
        MD
      end
    RUBY
  end

  it "reports, but never deletes, a blank line a backslash continues into or one inside an =begin comment" do
    expect_offense(<<~'RUBY')
      items.each do |item|
        result = foo \

      ^{} Empty line inside block body is not allowed
        bar
      =begin
      first

      ^{} Empty line inside block body is not allowed
      second
      =end
        result
      end
    RUBY
    expect_no_corrections
  end

  it "keeps the gap between two methods defined in a block" do
    expect_no_offenses(<<~RUBY)
      Class.new do
        def first
          1
        end

        def second
          2
        end
      end
    RUBY
  end

  it "flags a blank line after the last method in a block" do
    expect_offense(<<~RUBY)
      Class.new do
        def first
          1
        end

      ^{} Empty line inside block body is not allowed
        attr_reader :name
      end
    RUBY
  end

  it "leaves a file with no code alone" do
    expect_no_offenses("# frozen_string_literal: true\n")
  end
end
