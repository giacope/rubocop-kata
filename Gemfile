# frozen_string_literal: true

source "https://rubygems.org"
gemspec

gem "hashira", github: "giacope/hashira", branch: "main", group: :development
gem "kimera", github: "giacope/kimera", branch: "main", group: :test
gem "rspec", "~> 3.13", group: :test

# Test what users install: released gems, at the version a CI job pins.
gem "rubocop", ENV.fetch("RUBOCOP_VERSION", ">= 0")
gem "rubocop-elegant", ENV.fetch("RUBOCOP_ELEGANT_VERSION", ">= 0")
