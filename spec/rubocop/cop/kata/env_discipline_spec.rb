# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Kata::EnvDiscipline, :config) do
  let(:ruby_version) { 3.4 }

  it "flags ENV reads" do
    expect_offense(<<~RUBY)
      def home
        ENV["HOME"]
        ^^^ `ENV` belongs in the boot layer; pass configuration in.
        ::ENV.fetch("HOME")
        ^^^^^ `ENV` belongs in the boot layer; pass configuration in.
      end
    RUBY
  end

  it "allows ENV as a parameter default" do
    expect_no_offenses(<<~RUBY)
      def enabled?(env = ENV)
        env.fetch("FLAG", nil)
      end

      def url(address: ENV.fetch("URL", nil))
        address
      end
    RUBY
  end

  # eval/run in rubocop-kata; hashira's eval/probe/peak.rb, loaded with -r.
  it "takes code outside every class, module and method for a script's boot layer" do
    expect_no_offenses(<<~RUBY)
      exit(Session.new(ARGV, env: ENV.to_h).run)
      at_exit { File.write(ENV.fetch("REPORT"), "done") }
    RUBY
  end

  it "flags ENV read in a class body, a singleton class or a block inside a method" do
    expect_offense(<<~RUBY)
      class Settings
        HOME = ENV.fetch("HOME")
               ^^^ `ENV` belongs in the boot layer; pass configuration in.
        class << self
          def token = [1].map { ENV["TOKEN"] }
                                ^^^ `ENV` belongs in the boot layer; pass configuration in.
        end
      end
    RUBY
  end

  it "allows configuration passed in" do
    expect_no_offenses(<<~RUBY)
      configuration.home
    RUBY
  end

  it "leaves other constants alone, even ones with ENV-like shapes" do
    expect_no_offenses(<<~RUBY)
      SETTINGS.fetch("HOME")
      Sandbox::ENV.fetch("HOME")
    RUBY
  end
end
