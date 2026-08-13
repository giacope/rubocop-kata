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
require_relative "rubocop/cop/kata/builder_noun"
require_relative "rubocop/cop/kata/clock_discipline"
require_relative "rubocop/cop/kata/constructor_discipline"
require_relative "rubocop/cop/kata/env_discipline"
require_relative "rubocop/cop/kata/io_discipline"
require_relative "rubocop/cop/kata/no_abbreviation"
require_relative "rubocop/cop/kata/no_boolean_flag"
require_relative "rubocop/cop/kata/no_class_method_logic"
require_relative "rubocop/cop/kata/no_comments"
require_relative "rubocop/cop/kata/no_hash_as_object"
require_relative "rubocop/cop/kata/no_nil_return"
require_relative "rubocop/cop/kata/no_util_name"
require_relative "rubocop/cop/kata/prose_placement"
require_relative "rubocop/kata/plugin"
require_relative "rubocop/kata/version"
