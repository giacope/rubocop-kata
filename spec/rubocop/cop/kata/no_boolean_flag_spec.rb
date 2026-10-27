# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Kata::NoBooleanFlag, :config) do
  let(:ruby_version) { 3.4 }

  let(:cop_config) { { "AllowedMethods" => %w[respond_to? respond_to_missing? fetch] } }

  it "flags positional boolean arguments" do
    expect_offense(<<~RUBY)
      process(items, true)
                     ^^^^ A boolean flag is two methods trapped in one; call the method the flag chooses, split in two.
    RUBY
  end

  it "allows keyword booleans, comparisons, and assignments" do
    expect_no_offenses(<<~RUBY)
      process(items, dry_run: true)
      done == true
      config.verbose = false
    RUBY
  end

  it "allows the methods whose boolean is a protocol or a value, not a flag" do
    expect_no_offenses(<<~RUBY)
      respond_to?(name, true)
      options.fetch(:ssl, false)
    RUBY
  end

  # paper_trail, rodauth, sinatra: the callee stores or binds the boolean, it does not branch on it.
  it "allows a boolean stored under the name before it, bound after a placeholder, or expected" do
    expect_no_offenses(<<~RUBY)
      comment.update_attribute(:is_spam, false)
      auth_value_method :verify_account_set_password?, true
      @store.find_by_sql(["SELECT * FROM tracks WHERE public = ? AND :draft", true])
      connection.select_all("SELECT * FROM tracks WHERE public = :public", true)
      connection.select_all("SELECT * FROM \#{table} WHERE public = ?", false)
      expect(flipper).to receive(:enabled?).with(true)
    RUBY
  end

  it "still flags a flag passed on through send, or one before the setting's name" do
    expect_offense(<<~RUBY)
      record.send(:touch, true)
                          ^^^^ A boolean flag is two methods trapped in one; call the method the flag chooses, split in two.
      register(true, :verbose)
               ^^^^ A boolean flag is two methods trapped in one; call the method the flag chooses, split in two.
      log("ready", false)
                   ^^^^^ A boolean flag is two methods trapped in one; call the method the flag chooses, split in two.
      log("Shelf::Ready", false)
                          ^^^^^ A boolean flag is two methods trapped in one; call the method the flag chooses, split in two.
      double.with(true)
                  ^^^^ A boolean flag is two methods trapped in one; call the method the flag chooses, split in two.
    RUBY
  end

  # ahoy's `set_cookie("ahoy_track", true, nil, false)`: `value` is stored in the cookie, `use_domain` is a flag.
  it "allows a boolean the method it calls in the same file stores, and flags one it branches on" do
    expect_offense(<<~RUBY)
      class Tracker
        def defer
          set_cookie("ahoy_track", true, nil, false)
                                              ^^^^^ A boolean flag is two methods trapped in one; call the method the flag chooses, split in two.
          self.remember(true)
          keep(1, true)
          mark(true)
          tag(true)
          glob(false)
          @jar.set_cookie("other", true)
                                   ^^^^ A boolean flag is two methods trapped in one; call the method the flag chooses, split in two.
          late(true)
               ^^^^ A boolean flag is two methods trapped in one; call the method the flag chooses, split in two.
          spread(true)
                 ^^^^ A boolean flag is two methods trapped in one; call the method the flag chooses, split in two.
          twice(true)
                ^^^^ A boolean flag is two methods trapped in one; call the method the flag chooses, split in two.
          unknown(true)
                  ^^^^ A boolean flag is two methods trapped in one; call the method the flag chooses, split in two.
          short(1, true)
                   ^^^^ A boolean flag is two methods trapped in one; call the method the flag chooses, split in two.
          key(true)
              ^^^^ A boolean flag is two methods trapped in one; call the method the flag chooses, split in two.
          opt(true)
          lookup(1, true)
                    ^^^^ A boolean flag is two methods trapped in one; call the method the flag chooses, split in two.
          either(true)
                 ^^^^ A boolean flag is two methods trapped in one; call the method the flag chooses, split in two.
        end

        private

        def set_cookie(name, value, duration = nil, use_domain = nil)
          options = { value: value }
          options[:domain] = @domain if use_domain
          @cookies[name] = options
        end

        def remember(value) = @remembered = value
        def keep(key, value) = @store[key] = value
        def mark(value) = @record.marked = value
        def tag(value) = @@tag = value
        def glob(value) = $glob = value
        def late(value) = @log.write(value)
        def spread(*values) = @values = values
        def twice(value) = @twice = value
        def short(value) = @short = value
        def key(value) = @store[value] = 1
        def opt(value = nil) = @opt = value

        def lookup(record, was)
          @was = was
          value = record.find(was: was) if was
          value
        end

        def either(value) = @either = value || @fallback
      end

      class Other
        def twice(value) = value ? 1 : 2
      end
    RUBY
  end

  it "flags a positional parameter that defaults to a boolean, on either kind of def" do
    expect_offense(<<~RUBY)
      def process(items, strict = false, verbose: true)
                         ^^^^^^^^^^^^^^ `strict` defaults to a boolean flag, two methods trapped in one; split them, one method per value.
      end
      def self.build(items, strict = true)
                            ^^^^^^^^^^^^^ `strict` defaults to a boolean flag, two methods trapped in one; split them, one method per value.
      end
    RUBY
  end

  it "allows other defaults, and the parameters of an allowed method" do
    expect_no_offenses(<<~RUBY)
      def process(items, limit = 10, mode = nil)
      end
      def respond_to_missing?(name, include_private = false)
      end
    RUBY
  end

  context "with the shipped defaults" do
    let(:cop_config) { RuboCop::ConfigLoader.default_configuration.for_cop("Kata/NoBooleanFlag") }

    it "allows an exit status" do
      expect_no_offenses(<<~RUBY)
        exit(false)
        exit!(true)
      RUBY
    end
  end

  context "with the shipped allowed calls" do
    let(:cop_config) { {} }

    # ferrum's `pending.try_set(true)`: a Concurrent::IVar resolves to the boolean it stores.
    it "allows RSpec's matchers, queries and stored settings" do
      expect_no_offenses(<<~RUBY)
        expect(subject.enabled?(:beta)).to eq(true)
        expect(flag).to be(false)
        @store.where("settings.email_new_tracks = ?", true)
        @store.set(reader, true)
        pending.try_set(true)
        allow(gate).to receive(:open?).and_return(false)
      RUBY
    end

    # typeprof's `splat_flags.index(true)`, errbit's `confirm_err_actions.eql? false`: a value searched for or compared.
    it "allows a boolean searched for or compared" do
      expect_no_offenses(<<~RUBY)
        flags.index(true) || flags.rindex(false) || flags.count(true)
        actions.eql? false
        actions.equal?(true)
      RUBY
    end

    # statesman's `connection.quote(type_cast(true))`: the boolean is the SQL value rendered, not a switch.
    it "allows a boolean converted or rendered as a value" do
      expect_no_offenses(<<~RUBY)
        connection.quote(type_cast(true))
        model.connection.quote(false)
        ActiveModel::Type::Boolean.new.cast(true)
        JSON.dump(false)
        coder.serialize(true)
      RUBY
    end
  end
end
