# frozen_string_literal: true

require "rubocop"

module RuboCop
  module Kata
  end

  module Cop
    module Kata
    end
  end
end

require_relative "rubocop/cop/kata/agent_noun"
require_relative "rubocop/cop/kata/io_discipline"
require_relative "rubocop/cop/kata/no_comments"
require_relative "rubocop/cop/kata/prose_placement"
require_relative "rubocop/kata/plugin"
require_relative "rubocop/kata/version"
