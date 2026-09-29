# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Kata::GoodVariableName, :config) do
  let(:defaults) { YAML.load_file("config/default.yml").fetch("Kata/GoodVariableName") }
  let(:cop_config) { defaults.merge("Terms" => [], "AllowedNames" => []) }

  def offense(name)
    "`#{name}` needs two words: the second word names an object you have not introduced yet. " \
      "Name that object, use a `Prefixes`/`Suffixes` role word — or, if `#{name}` is one domain concept " \
      "here, add it to `Terms`."
  end

  context "with the shipped AllowedNames" do
    let(:cop_config) { defaults }

    it "allows the respond_to_missing? protocol argument" do
      expect_no_offenses(<<~RUBY)
        def respond_to_missing?(name, _include_private = false)
          true
        end
      RUBY
    end

    it "allows grammatical suffixes, role prefixes, and protocol vocabulary" do
      expect_no_offenses(<<~RUBY)
        user_id = 1
        timeout_ms = 1
        max_retries = 1
        start_time = 1
        end_date = 1
        time_zone = 1
        ip_address = 1
        user_agent = 1
        first_name = 1
      RUBY
    end

    it "still prices owner-plus-property names" do
      expect_offense(<<~RUBY)
        error_message = 1
        ^^^^^^^^^^^^^ #{offense("error_message")}
      RUBY
    end
  end

  it "allows single-word locals, parameters, and keyword arguments" do
    expect_no_offenses(<<~RUBY)
      def run(source, verdict = nil, timeout: nil)
        report = source
      end
    RUBY
  end

  it "allows sigils and the underscore conventions" do
    expect_no_offenses(<<~RUBY)
      def run(_unused)
        @source = 1
        @@registry = 2
        $stdout = 3
        @_cache = 4
        _ = 5
      end
    RUBY
  end

  it "allows role prefixes and suffixes" do
    expect_no_offenses(<<~RUBY)
      def run(for_diff, from_message, points_at, tests_for)
        each_group = for_diff
        @with_timeout = from_message
        fake_adapter = points_at
      end
    RUBY
  end

  it "flags two-word locals" do
    expect_offense(<<~RUBY, message: offense("matching_ids"))
      def run
        matching_ids = 1
        ^^^^^^^^^^^^ %{message}
      end
    RUBY
  end

  it "flags two-word parameters and keyword arguments" do
    expect_offense(<<~RUBY, message: offense("covering_lines"))
      def run(covering_lines)
              ^^^^^^^^^^^^^^ %{message}
      end
    RUBY
    expect_offense(<<~RUBY, message: offense("apply_excludes"))
      def run(apply_excludes: nil)
              ^^^^^^^^^^^^^^ %{message}
      end
    RUBY
  end

  it "flags sigilled and underscored two-word names" do
    expect_offense(<<~RUBY, message: offense("@build_adapter"))
      @build_adapter = 1
      ^^^^^^^^^^^^^^ %{message}
    RUBY
    expect_offense(<<~RUBY, message: offense("@_covering_lines"))
      @_covering_lines = 1
      ^^^^^^^^^^^^^^^^ %{message}
    RUBY
    expect_offense(<<~RUBY, message: offense("$source_root"))
      $source_root = 1
      ^^^^^^^^^^^^ %{message}
    RUBY
  end

  it "flags three-word names" do
    expect_offense(<<~RUBY, message: offense("fork_pool_worker"))
      def run
        fork_pool_worker = 1
        ^^^^^^^^^^^^^^^^ %{message}
      end
    RUBY
  end

  context "with domain terms declared" do
    let(:cop_config) { defaults.merge("Terms" => %w[changed_lines mutant_id], "AllowedNames" => []) }

    it "allows them, sigils included" do
      expect_no_offenses(<<~RUBY)
        def run(mutant_id)
          changed_lines = mutant_id
          @mutant_id = changed_lines
        end
      RUBY
    end
  end

  context "with the raw escape hatch" do
    let(:cop_config) { defaults.merge("Terms" => [], "AllowedNames" => %w[matching_ids]) }

    it "allows the listed name" do
      expect_no_offenses(<<~RUBY)
        def run
          matching_ids = 1
        end
      RUBY
    end
  end

  it "flags two-word names in class variables and every argument kind" do
    expect_offense(<<~RUBY)
      def run(customer_address = nil, billing_address:, shipping_address: nil)
              ^^^^^^^^^^^^^^^^ #{offense("customer_address")}
                                      ^^^^^^^^^^^^^^^ #{offense("billing_address")}
                                                        ^^^^^^^^^^^^^^^^ #{offense("shipping_address")}
        @@customer_address = customer_address
        ^^^^^^^^^^^^^^^^^^ #{offense("@@customer_address")}
      end
    RUBY
  end

  context "with anonymous parameters, which need Ruby 3.1" do
    let(:ruby_version) { 3.4 }

    it "flags two-word rest, keyword-rest, and block parameters, and skips anonymous ones" do
      expect_offense(<<~RUBY)
        def run(*extra_things, **more_options, &done_callback)
                 ^^^^^^^^^^^^ #{offense("extra_things")}
                                 ^^^^^^^^^^^^ #{offense("more_options")}
                                                ^^^^^^^^^^^^^ #{offense("done_callback")}
        end
        def pass(*, **, &)
        end
      RUBY
    end
  end

  it "flags a name that breaks the word pattern, even as one word" do
    expect_offense(<<~RUBY)
      customerAddress = 1
      ^^^^^^^^^^^^^^^ #{offense("customerAddress")}
    RUBY
  end

  context "with a sigiled name whose bare form is in the escape hatch" do
    let(:cop_config) { defaults.merge("Terms" => [], "AllowedNames" => %w[matching_ids]) }

    it "allows the listed name behind its sigil" do
      expect_no_offenses(<<~RUBY)
        @matching_ids = 1
      RUBY
    end
  end
end
