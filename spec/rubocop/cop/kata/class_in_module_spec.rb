# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT
# Derived from rubocop-elegant (https://github.com/yegor256/rubocop-elegant), see LICENSE.txt

RSpec.describe(RuboCop::Cop::Kata::ClassInModule) do
  include TabledCop

  let(:cop) { described_class.new(RuboCop::Config.new) }

  it_behaves_like(
    "tabled cop", allowed: {
      "class_inside_single_module" => "module Foo\n  class Bar\n  end\nend",
      "class_inside_nested_modules" => "module Foo\n  module Baz\n    class Bar\n    end\n  end\nend",
      "compact_namespaced_class" => "class Foo::Bar\nend",
      "deeply_namespaced_compact_class" => "class Foo::Bar::Baz\nend",
      "module_without_any_class" => "module Foo\nend",
      "top_level_method_only" => "def foo\nend",
      "nested_class_inside_class_inside_module" => "module Foo\n  class Bar\n    class Baz\n    end\n  end\nend",
      "class_with_inheritance_inside_module" => "module Foo\n  class Bar < StandardError\n  end\nend",
      "class_nested_in_compact_namespaced_class" => "class Foo::Bar\n  class Baz < StandardError\n  end\nend",
      "migration_loaded_by_its_top_level_name" => "class CreateSlugs < ActiveRecord::Migration[7.1]\nend",
      "migration_without_a_version" => "class CreateSlugs < ::ActiveRecord::Migration\nend",
      "migration_through_a_constant" => "BASE = if old\n  ActiveRecord::Migration\nelse\n  " \
        "ActiveRecord::Migration[7.1]\nend\nclass CreateSlugs < BASE\nend"
    }, violations: {
      "plain_top_level_class" => ["class Foo\nend", 1],
      "top_level_class_with_explicit_root" => ["class ::Foo\nend", 1],
      "top_level_class_with_nested_class" => ["class Foo\n  class Bar\n  end\nend", 1],
      "two_top_level_classes" => ["class Foo\nend\nclass Bar\nend", 2],
      "top_level_class_with_inheritance" => ["class Foo < StandardError\nend", 1],
      "root_scoped_class_inside_a_class" => ["class Foo::Bar\n  class ::Baz\n  end\nend", 1],
      "root_scoped_class_inside_a_module" => ["module Foo\n  class ::Baz\n  end\nend", 1],
      "top_level_record" => ["class Slug < ActiveRecord::Base\nend", 1],
      "top_level_class_under_another_library_migration" => ["class Slug < Legacy::ActiveRecord::Migration\nend", 1],
      "top_level_class_under_a_constant_another_namespace_holds" =>
        ["Legacy::BASE = ActiveRecord::Migration\nBASE = Class.new\nclass Slug < BASE\nend", 1],
      "top_level_class_under_a_qualified_constant" =>
        ["BASE = ActiveRecord::Migration\nclass Slug < Legacy::BASE\nend", 1]
    }
  )

  it "names the class in its message" do
    expect(offenses("class ::Foo\nend").first.message)
      .to(end_with(": Class ::Foo must be defined inside a module, not globally"))
  end

  context "with core classes listed" do
    let(:cop) { described_class.new(RuboCop::Config.new("Kata/ClassInModule" => { "CoreClasses" => %w[String] })) }

    it "asks for a refinement or a decorator when a file reopens a core class" do
      advice = "Reopening `String` patches it for every caller; use a refinement (`refine String`) or a decorator"
      expect(offenses("class String\n  def shout = upcase\nend").first.message).to(include(advice))
    end

    it "keeps the namespace advice for a class that only shares the name, or defines it anew" do
      messages = offenses("class Strings\nend\nclass String < Base\nend").map { it.message[/Class .*/] }
      expect(messages).to(eq(%w[Strings String].map { "Class #{it} must be defined inside a module, not globally" }))
    end
  end

  # roda, pagy, thor and money reopen the gem's own top-level class in every plugin file.
  context "with the project's files" do
    include ProjectFiles

    let(:setting) do
      { "Kata/ClassInModule" => { "OwnedPaths" => ["lib/**/*.rb"] }, "Kata" => { "Roots" => %w[Shelf] } }
    end
    let(:files) do
      {
        "lib/shelf.rb" => "class Shelf\n  VERSION = 1\nend\n",
        "lib/shelf/plugins/cache.rb" => "class Shelf\n  module Cache\n  end\nend\n",
        "lib/build.rb" => "class Build\nend\n", "lib/build/step.rb" => "class Build\n  class Step\n  end\nend\n",
        "lib/jobs/a.rb" => "class Job\nend\n",
        "lib/jobs/b.rb" => "class Job\n  run\nrescue StandardError\n  nil\nend\n",
        "lib/tasks/a.rb" => "class Task\n  def a = 1\nend\n",
        "lib/tasks/b.rb" => "class Task\n  def b = 1\n  def c = 2\nend\n"
      }
    end

    it "passes the project's root class, and judges a class reopened in many files once" do
      found = files.keys.map { project_offenses(files, it).size }
      expect(found).to(eq([0, 0, 1, 0, 0, 1, 0, 1]))
    end
  end
end
