# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Kata::EnvDiscipline, :config) do
  it "flags ENV reads" do
    expect_offense(<<~RUBY)
      ENV["HOME"]
      ^^^ `ENV` belongs in the boot layer; pass configuration in.
      ::ENV.fetch("HOME")
      ^^^^^ `ENV` belongs in the boot layer; pass configuration in.
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
