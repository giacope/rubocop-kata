# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Kata::BuilderNoun, :config) do
  let(:cop_config) { { "BannedPrefixes" => %w[get calculate], "AllowedNames" => %w[get_callbacks] } }

  it "flags verb-prefixed builders" do
    expect_offense(<<~RUBY)
      def calculate_total
          ^^^^^^^^^^^^^^^ A builder is named for what it returns: `total`, not `calculate_total`.
      end
      def self.get_name
               ^^^^^^^^ A builder is named for what it returns: `name`, not `get_name`.
      end
    RUBY
  end

  it "allows a name an external API dictates" do
    expect_no_offenses(<<~RUBY)
      def get_callbacks
      end
    RUBY
  end

  it "allows nouns and bare verbs" do
    expect_no_offenses(<<~RUBY)
      def total
      end
      def calculate
      end
      def getaway
      end
    RUBY
  end

  it "leaves a method that calls super to its ancestor's name" do
    expect_no_offenses(<<~RUBY)
      def calculate_total(*)
        super + 1
      end
    RUBY
  end

  context "with the project's library" do
    include TabledCop

    let(:root) { Dir.mktmpdir("kata-builders") }
    let(:cop) do
      shipped = { "Kata/BuilderNoun" => { "BannedPrefixes" => %w[get], "OwnedPaths" => ["lib/**/*.rb"] } }
      described_class.new(RuboCop::Config.new(shipped, File.join(root, ".rubocop.yml")))
    end

    before do
      FileUtils.mkdir_p(File.join(root, "lib"))
      library = "class Chain\n  def held(owner) = owner.__send__(:get_callbacks)\nend\n"
      File.write(File.join(root, "lib", "chain.rb"), library)
    end

    after { FileUtils.rm_rf(root) }

    # kimera's schemata_spec mirrors ActiveSupport's private get_callbacks.
    it "leaves a stand-in for a message the project sends but never defines to the caller's name" do
      expect(offenses("def get_callbacks(name) = name\ndef get_name = 1\n").map(&:line)).to(eq([2]))
    end
  end
end
