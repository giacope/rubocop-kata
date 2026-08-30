# frozen_string_literal: true

require "rubocop"
require "rubocop-kata"
require "rubocop/rspec/support"
require_relative "support/tabled_cop"

RSpec.configure do |config|
  config.include(RuboCop::RSpec::ExpectOffense)
  config.disable_monkey_patching!
  config.order = :random
end
