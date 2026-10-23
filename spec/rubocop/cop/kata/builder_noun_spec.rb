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

  # padrino-gen, flipper's generators: a step that writes a file returns no built object.
  context "with commands" do
    let(:ruby_version) { 3.4 }
    let(:cop_config) { { "BannedPrefixes" => %w[generate], "Commands" => %w[File.write FileUtils invoke] } }

    it "leaves a method that ends in a command to its verb" do
      expect_offense(<<~RUBY)
        def generate_initializer = File.write("config/shelf.rb", "Shelf.start")
        def generate_tree(dir) = FileUtils.mkdir_p(dir)
        def generate_active_record
          say "creating"
          invoke "flipper:active_record"
        end
        def generate_report = File.read("report.txt")
            ^^^^^^^^^^^^^^^ A builder is named for what it returns: `report`, not `generate_report`.
        def generate_copy = files.map { File.write(it, "") }
            ^^^^^^^^^^^^^ A builder is named for what it returns: `copy`, not `generate_copy`.
        def generate_log = logger.write("x")
            ^^^^^^^^^^^^ A builder is named for what it returns: `log`, not `generate_log`.
        def generate_site(dir) = FileUtils.cd(dir) { build }
        def generate_list = invoke.map { it }
            ^^^^^^^^^^^^^ A builder is named for what it returns: `list`, not `generate_list`.
      RUBY
    end
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
      File.write(File.join(root, "lib", "adapter.rb"), "module Adapter\n  def get_all = 1\nend\n")
    end

    after { FileUtils.rm_rf(root) }

    # kimera's schemata_spec mirrors ActiveSupport's private get_callbacks.
    it "leaves a stand-in for a message the project sends but never defines to the caller's name" do
      expect(offenses("def get_callbacks(name) = name\ndef get_name = 1\n").map(&:line)).to(eq([2]))
    end

    # flipper: each adapter implements Flipper::Adapter#get_all.
    it "reports a name once, where the protocol chose it, not in each implementation" do
      source = "class Memory\n  include Adapter\n  def get_all = {}\n  def get_one = 1\nend\n"
      expect(offenses(source).map(&:line)).to(eq([4]))
    end
  end
end
