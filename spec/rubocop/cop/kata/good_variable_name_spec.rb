# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Kata::GoodVariableName, :config) do
  let(:defaults) { YAML.load_file("config/default.yml", aliases: true).fetch("Kata/GoodVariableName") }
  let(:cop_config) { defaults.merge("Terms" => [], "AllowedNames" => []) }

  def offense(name, count = 3, max = 2)
    "`#{name}` strings #{count} words together, past the #{max} a name carries: the words describe an object " \
      "you have not introduced yet. Name that object, give a role a `Prefixes`/`Suffixes` word — or, " \
      "if `#{name}` is one domain concept here, add it to `Terms`."
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

    it "allows a two-word name and prices a three-word one" do
      expect_offense(<<~RUBY)
        error_message = 1
        last_error_message = 1
        ^^^^^^^^^^^^^^^^^^ #{offense("last_error_message")}
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

  it "allows two-word locals, parameters, and sigilled names" do
    expect_no_offenses(<<~RUBY)
      def run(covering_lines, apply_excludes: nil)
        matching_ids = 1
        @build_adapter = 1
        @_covering_lines = 1
        $source_root = 1
      end
    RUBY
  end

  it "flags three-word locals, parameters, and sigilled names" do
    expect_offense(<<~RUBY)
      def run(covering_test_lines, apply_exclude_globs: nil)
              ^^^^^^^^^^^^^^^^^^^ #{offense("covering_test_lines")}
                                   ^^^^^^^^^^^^^^^^^^^ #{offense("apply_exclude_globs")}
        fork_pool_worker = 1
        ^^^^^^^^^^^^^^^^ #{offense("fork_pool_worker")}
        @_covering_test_lines = 1
        ^^^^^^^^^^^^^^^^^^^^^ #{offense("@_covering_test_lines")}
        $source_tree_root = 1
        ^^^^^^^^^^^^^^^^^ #{offense("$source_tree_root")}
      end
    RUBY
  end

  context "with MaxWords 1, for a team that wants one word" do
    let(:cop_config) { defaults.merge("Terms" => [], "AllowedNames" => [], "MaxWords" => 1) }

    it "flags two words, and allows a word with its roles" do
      expect_offense(<<~RUBY)
        matching_ids = 1
        ^^^^^^^^^^^^ #{offense("matching_ids", 2, 1)}
        user_id = 1
      RUBY
    end
  end

  context "with domain terms declared" do
    let(:cop_config) { defaults.merge("Terms" => %w[changed_source_lines date_of_birth], "AllowedNames" => []) }

    it "allows them, sigils included" do
      expect_no_offenses(<<~RUBY)
        def run(date_of_birth)
          changed_source_lines = date_of_birth
          @date_of_birth = changed_source_lines
        end
      RUBY
    end
  end

  context "with the raw escape hatch" do
    let(:cop_config) { defaults.merge("Terms" => [], "AllowedNames" => %w[matching_test_ids]) }

    it "allows the listed name" do
      expect_no_offenses(<<~RUBY)
        def run
          matching_test_ids = 1
        end
      RUBY
    end
  end

  it "flags three-word names in class variables and every argument kind" do
    expect_offense(<<~RUBY)
      def run(customer_home_address = nil, billing_zip_area:, shipping_box_label: nil)
              ^^^^^^^^^^^^^^^^^^^^^ #{offense("customer_home_address")}
                                           ^^^^^^^^^^^^^^^^ #{offense("billing_zip_area")}
                                                              ^^^^^^^^^^^^^^^^^^ #{offense("shipping_box_label")}
        @@customer_home_address = customer_home_address
        ^^^^^^^^^^^^^^^^^^^^^^^ #{offense("@@customer_home_address")}
      end
    RUBY
  end

  context "with anonymous parameters, which need Ruby 3.1" do
    let(:ruby_version) { 3.4 }

    it "flags three-word rest, keyword-rest, and block parameters, and skips anonymous ones" do
      expect_offense(<<~RUBY)
        def run(*extra_test_things, **more_merge_options, &done_hook_callback)
                 ^^^^^^^^^^^^^^^^^ #{offense("extra_test_things")}
                                      ^^^^^^^^^^^^^^^^^^ #{offense("more_merge_options")}
                                                           ^^^^^^^^^^^^^^^^^^ #{offense("done_hook_callback")}
        end
        def pass(*, **, &)
        end
      RUBY
    end
  end

  it "flags a name that breaks the word pattern, even as one word" do
    expect_offense(<<~RUBY)
      customerAddress = 1
      ^^^^^^^^^^^^^^^ `customerAddress`: the segment `customerAddress` does not match `Pattern`; a segment is one lowercase word.
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

  it "leaves Ruby's predefined globals alone" do
    expect_no_offenses(<<~RUBY)
      $VERBOSE = nil
      $PROGRAM_NAME = "worker"
      $0 = "worker"
      $stdout = StringIO.new
    RUBY
  end

  # pundit's `@_pundit_policy_scoped`, solid_queue's `solid_queue_job`: code mixed into host classes.
  context "with the project's root constants" do
    let(:cop_config) do
      defaults.merge("Terms" => [], "AllowedNames" => [], "Roots" => %w[Pundit SolidQueue RubyEventStore])
    end

    it "counts the root's snake-case name as a role prefix" do
      expect_offense(<<~RUBY)
        @_pundit_policy_scoped = solid_queue_claimed_job = 1
        policy_scope_cache = 1
        ^^^^^^^^^^^^^^^^^^ `policy_scope_cache` strings 3 words together, past the 2 a name carries: the words describe an object you have not introduced yet. Name that object, give a role a `Prefixes`/`Suffixes` word — or, if `policy_scope_cache` is one domain concept here, add it to `Terms`.
        pundit = ruby_event_store = 1
      RUBY
    end
  end
end
