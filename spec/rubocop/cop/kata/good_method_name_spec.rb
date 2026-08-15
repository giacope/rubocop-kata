# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Kata::GoodMethodName, :config) do
  let(:defaults) { YAML.load_file("config/default.yml").fetch("Kata/GoodMethodName") }
  let(:cop_config) { defaults.merge("Terms" => [], "AllowedNames" => []) }

  def offense(name)
    "`#{name}` needs two words: either a concept is missing, or the method belongs on the object " \
      "the second word names. Say it in one word, move it, give the role a `Prefixes`/`Suffixes` " \
      "word — or, if `#{name}` is one domain concept here, add it to `Terms`."
  end

  it "allows single-word names" do
    expect_no_offenses(<<~RUBY)
      def coverage
      end
      def survivors?
      end
      def kill!
      end
      def source=(value)
      end
    RUBY
  end

  it "allows role prefixes" do
    expect_no_offenses(<<~RUBY)
      def after_fork
      end
      def before_exit
      end
      def around_mutant
      end
      def on_def
      end
      def each_group
      end
      def for_diff
      end
      def from_message
      end
      def to_h
      end
      def by_kill_likelihood
      end
      def with_timeout
      end
      def test_invoke_private
      end
      def fake_adapter
      end
    RUBY
  end

  it "allows role suffixes" do
    expect_no_offenses(<<~RUBY)
      def file_of
      end
      def tests_for
      end
      def points_at
      end
    RUBY
  end

  it "flags verb plus receiver" do
    expect_offense(<<~RUBY, message: offense("build_adapter"))
      def build_adapter
          ^^^^^^^^^^^^^ %{message}
      end
    RUBY
  end

  it "flags the rest of the two-word smells" do
    %w[assemble_report drive_pool cmd_run apply_excludes matching_ids covering_count].each do |name|
      expect_offense(<<~RUBY, name: name, message: offense(name))
        def %{name}
            ^{name} %{message}
        end
      RUBY
    end
  end

  it "flags two-word predicates, bangs, and setters" do
    expect_offense(<<~RUBY, message: offense("harness_critical?"))
      def harness_critical?
          ^^^^^^^^^^^^^^^^^ %{message}
      end
    RUBY
    expect_offense(<<~RUBY, message: offense("class_body?"))
      def class_body?
          ^^^^^^^^^^^ %{message}
      end
    RUBY
    expect_offense(<<~RUBY, message: offense("source_root="))
      def source_root=(value)
          ^^^^^^^^^^^^ %{message}
      end
    RUBY
  end

  it "flags three-word names, role prefix or not" do
    expect_offense(<<~RUBY, message: offense("install_enum_guard!"))
      def install_enum_guard!
          ^^^^^^^^^^^^^^^^^^^ %{message}
      end
    RUBY
    expect_offense(<<~RUBY, message: offense("fork_pool_worker"))
      def self.fork_pool_worker
               ^^^^^^^^^^^^^^^^ %{message}
      end
    RUBY
  end

  it "flags names longer than the pattern allows" do
    expect_offense(<<~RUBY, message: offense("supercalifragilistic"))
      def supercalifragilistic
          ^^^^^^^^^^^^^^^^^^^^ %{message}
      end
    RUBY
  end

  context "with domain terms declared" do
    let(:cop_config) do
      defaults.merge("Terms" => %w[changed_files covering_tests mutant_id source_root test_id], "AllowedNames" => [])
    end

    it "allows them" do
      expect_no_offenses(<<~RUBY)
        def changed_files
        end
        def covering_tests
        end
        def mutant_id
        end
        def source_root
        end
        def test_id
        end
      RUBY
    end
  end

  context "with the raw escape hatch" do
    let(:cop_config) { defaults.merge("Terms" => [], "AllowedNames" => %w[build_adapter]) }

    it "allows the listed name" do
      expect_no_offenses(<<~RUBY)
        def build_adapter
        end
      RUBY
    end
  end
end
