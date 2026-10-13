# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Kata::IoDiscipline, :config) do
  it "flags bare output calls" do
    expect_offense(<<~RUBY)
      puts "report"
      ^^^^^^^^^^^^^ Write through the injected `@io`, not bare `puts`.
      warn "oops"
      ^^^^^^^^^^^ Write through the injected `@io`, not bare `warn`.
      pp value
      ^^^^^^^^ Write through the injected `@io`, not bare `pp`.
      p value
      ^^^^^^^ Write through the injected `@io`, not bare `p`.
    RUBY
  end

  it "flags a bare call without arguments" do
    expect_offense(<<~RUBY)
      puts
      ^^^^ Write through the injected `@io`, not bare `puts`.
    RUBY
  end

  it "allows writing through a receiver" do
    expect_no_offenses(<<~RUBY)
      @io.puts "report"
      $stderr.puts "oops"
      io.p(value)
      Kernel.warn("x")
    RUBY
  end

  it "leaves other bare calls alone" do
    expect_no_offenses(<<~RUBY)
      print_report
      putc "x"
    RUBY
  end

  context "with the shipped defaults" do
    let(:root) { File.expand_path("../../../..", __dir__) }
    let(:shipped) { YAML.load_file(File.join(root, "config/default.yml"), aliases: true).slice("Kata/IoDiscipline") }
    let(:config) { RuboCop::Config.new(shipped, File.join(root, ".rubocop.yml")) }

    it "exempts the boot layer and the test suite, and nothing else" do
      cop = described_class.new(config)
      paths = %w[
        exe/tool bin/setup script/seed config/boot.rb lib/tasks/a.rake Rakefile spec/a_spec.rb test/a_test.rb lib/a.rb
      ]
      expect(paths.select { cop.relevant_file?(File.join(root, it)) }).to(eq(%w[lib/a.rb]))
    end
  end
end
