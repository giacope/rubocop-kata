# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Kata::JustifiedDirective, :config) do
  let(:cop_config) { { "MinWords" => 3 } }

  it "flags a disable that gives no reason" do
    expect_offense(<<~RUBY)
      # rubocop:disable Kata/GoodClassName
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Say why after `--`: `# rubocop:disable Kata/GoodClassName -- <reason>`; a reason of at least 3 words.
      class Fetcher
      end
      # rubocop:enable Kata/GoodClassName
    RUBY
  end

  it "flags a trailing disable, a todo and a disable-next-line too" do
    expect_offense(<<~RUBY)
      VALUE = load # rubocop:disable Security/MarshalLoad, Style/Send
                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Say why after `--`: `# rubocop:disable Security/MarshalLoad, Style/Send -- <reason>`; a reason of at least 3 words.
      # rubocop:todo Metrics/AbcSize
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Say why after `--`: `# rubocop:disable Metrics/AbcSize -- <reason>`; a reason of at least 3 words.
      # rubocop:disable-next-line Style/Send
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Say why after `--`: `# rubocop:disable Style/Send -- <reason>`; a reason of at least 3 words.
      VALUE.send(:x)
    RUBY
  end

  it "flags a reason too short to say anything" do
    expect_offense(<<~RUBY)
      VALUE = load # rubocop:disable Security/MarshalLoad -- trusted
                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Say why after `--`: `# rubocop:disable Security/MarshalLoad -- <reason>`; a reason of at least 3 words.
    RUBY
  end

  it "allows a disable that says why" do
    expect_no_offenses(<<~RUBY)
      # rubocop:disable Kata/GoodClassName -- Avo resolves the handler by this name
      class Fetcher
      end
      # rubocop:enable Kata/GoodClassName
      VALUE = load # rubocop:disable Security/MarshalLoad -- reads back its own child
      OTHER = load # rubocop:disable Security/MarshalLoad -- its own child
    RUBY
  end

  it "cannot see a `disable all`, which silences this cop on its own line too; doctor lists it" do
    expect_no_offenses(<<~RUBY)
      # rubocop:disable all
      VALUE = 1
      # rubocop:enable all
    RUBY
  end

  it "leaves enable directives and other comments alone" do
    expect_no_offenses(<<~RUBY)
      # rubocop:enable Kata/GoodClassName
      # the rubocop:disable syntax is documented upstream
      VALUE = 1
    RUBY
  end

  context "with the shipped defaults" do
    let(:config) do
      RuboCop::Config.new(RuboCop::ConfigLoader.default_configuration.to_h, "/project/.rubocop.yml")
    end

    it "replaces the blanket ban on inline disables" do
      cops = %w[Style/DisableCopsWithinSourceCodeDirective Kata/JustifiedDirective]
      settings = [*cops.map { config.for_cop(it)["Enabled"] }, config.for_cop(cops.last)["MinWords"]]
      expect(settings).to(eq([false, true, 3]))
    end
  end
end
