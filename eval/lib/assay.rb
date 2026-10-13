# frozen_string_literal: true

require "fileutils"
require "json"
require "open3"
require "prism"
require "yaml"
require "zlib"

module Assay
  ROOT = File.expand_path("..", __dir__)
end

require_relative "assay/shell"
require_relative "assay/bundle"
require_relative "assay/snippets"
require_relative "assay/lexicon"
require_relative "assay/settings"
require_relative "assay/console"
require_relative "assay/census"
require_relative "assay/corpus"
require_relative "assay/board"
require_relative "assay/comparison"
require_relative "assay/session"
