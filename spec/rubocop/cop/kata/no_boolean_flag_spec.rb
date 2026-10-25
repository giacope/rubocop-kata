# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Kata::NoBooleanFlag, :config) do
  let(:ruby_version) { 3.4 }

  let(:cop_config) { { "AllowedMethods" => %w[respond_to? respond_to_missing? fetch] } }

  it "flags positional boolean arguments" do
    expect_offense(<<~RUBY)
      process(items, true)
                     ^^^^ A boolean flag is two methods trapped in one; split them or name the argument.
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
                          ^^^^ A boolean flag is two methods trapped in one; split them or name the argument.
      register(true, :verbose)
               ^^^^ A boolean flag is two methods trapped in one; split them or name the argument.
      log("ready", false)
                   ^^^^^ A boolean flag is two methods trapped in one; split them or name the argument.
      log("Shelf::Ready", false)
                          ^^^^^ A boolean flag is two methods trapped in one; split them or name the argument.
      double.with(true)
                  ^^^^ A boolean flag is two methods trapped in one; split them or name the argument.
    RUBY
  end

  it "flags a positional parameter that defaults to a boolean, on either kind of def" do
    expect_offense(<<~RUBY)
      def process(items, strict = false, verbose: true)
                         ^^^^^^^^^^^^^^ `strict` defaults to a boolean flag, two methods trapped in one; split them or make it a keyword.
      end
      def self.build(items, strict = true)
                            ^^^^^^^^^^^^^ `strict` defaults to a boolean flag, two methods trapped in one; split them or make it a keyword.
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

    it "allows RSpec's matchers, queries and stored settings" do
      expect_no_offenses(<<~RUBY)
        expect(subject.enabled?(:beta)).to eq(true)
        expect(flag).to be(false)
        @store.where("settings.email_new_tracks = ?", true)
        @store.set(reader, true)
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
  end
end
