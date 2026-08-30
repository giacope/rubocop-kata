# frozen_string_literal: true

require_relative "lib/rubocop/kata/version"

Gem::Specification.new do |spec|
  spec.name = "rubocop-kata"
  spec.version = RuboCop::Kata::VERSION
  spec.authors = ["Giacomo GK"]
  spec.email = ["giaco@hey.com"]
  spec.summary = "Practiced forms for Ruby: a RuboCop plugin with opinionated defaults and eighteen house cops"
  spec.description = "Bundles a curated RuboCop stack (rspec, performance, elegant, packaging, " \
    "thread_safety) behind one dependency, layers opinionated style defaults on top, and adds " \
    "eighteen cops of its own — naming (GoodMethodName, GoodVariableName, dictionary-backed " \
    "RealWords, GoodClassName, GoodModuleName, BuilderNoun), discipline (IoDiscipline, ClockDiscipline, " \
    "EnvDiscipline, ConstructorDiscipline, NoClassMethodLogic), and shape (NoComments, " \
    "NoBooleanFlag, NoHashAsObject, ProsePlacement). The rubocop-kata command reports dead " \
    "configuration (doctor), buckets a backlog into the stages that cause each other (plan), " \
    "and prints an agent skill for working it (skill)."
  spec.homepage = "https://github.com/giacope/rubocop-kata"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.4"
  spec.metadata = {
    "source_code_uri" => spec.homepage,
    "changelog_uri" => "#{spec.homepage}/blob/main/CHANGELOG.md",
    "bug_tracker_uri" => "#{spec.homepage}/issues",
    "default_lint_roller_plugin" => "RuboCop::Kata::Plugin",
    "rubygems_mfa_required" => "true"
  }
  spec.files = Dir[
    "lib/**/*.rb", "config/*.yml", "data/*", "exe/*", "skills/**/*",
    "README.md", "CHANGELOG.md", "LICENSE*"
  ].select { File.file?(it) }
  spec.bindir = "exe"
  spec.executables = ["rubocop-kata"]
  spec.require_paths = ["lib"]
  spec.add_dependency("lint_roller", "~> 1.1")
  spec.add_dependency("rubocop", "~> 1.75")
  spec.add_dependency("rubocop-elegant", "~> 0.7")
  spec.add_dependency("rubocop-packaging", "~> 0.6")
  spec.add_dependency("rubocop-performance", "~> 1.25")
  spec.add_dependency("rubocop-rspec", "~> 3.6")
  spec.add_dependency("rubocop-thread_safety", "~> 0.7")
end
