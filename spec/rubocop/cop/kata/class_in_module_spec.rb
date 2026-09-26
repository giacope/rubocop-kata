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
      "class_nested_in_compact_namespaced_class" => "class Foo::Bar\n  class Baz < StandardError\n  end\nend"
    }, violations: {
      "plain_top_level_class" => ["class Foo\nend", 1],
      "top_level_class_with_explicit_root" => ["class ::Foo\nend", 1],
      "top_level_class_with_nested_class" => ["class Foo\n  class Bar\n  end\nend", 1],
      "two_top_level_classes" => ["class Foo\nend\nclass Bar\nend", 2],
      "top_level_class_with_inheritance" => ["class Foo < StandardError\nend", 1],
      "root_scoped_class_inside_a_class" => ["class Foo::Bar\n  class ::Baz\n  end\nend", 1],
      "root_scoped_class_inside_a_module" => ["module Foo\n  class ::Baz\n  end\nend", 1]
    }
  )

  it "names the class in its message" do
    expect(offenses("class ::Foo\nend").first.message)
      .to(end_with(": Class ::Foo must be defined inside a module, not globally"))
  end
end
