# frozen_string_literal: true

class Assay::Bundle
  GEMFILE = <<~RUBY
    source "https://rubygems.org"

    gem "rubocop-kata", path: %<kata>p
    gem "rubocop-elegant", %<elegant>p
  RUBY

  attr_reader :kata

  def initialize(kata, work, shell, elegant:)
    @kata = kata
    @work = work
    @shell = shell
    @elegant = elegant
  end

  def prepare
    FileUtils.mkdir_p(@work)
    File.write(gemfile, format(GEMFILE, kata: @kata, elegant: @elegant))
    outcome = @shell.run("bundle", "install", "--local", "--quiet", dir: @work, env: scope)
    raise "bundle install failed: #{outcome.stderr}#{outcome.stdout}" unless outcome.status.zero?
    self
  end

  def rubocop(*arguments, dir:) = shell.run("bundle", "exec", "rubocop", *arguments, dir: dir)

  def ruby(*arguments, dir:, env: {}) = shell.run("bundle", "exec", "ruby", *arguments, dir: dir, env: env)

  def shell = @shell.with(scope)

  def identity
    {
      "path" => @kata,
      "commit" => git("rev-parse", "HEAD"),
      "dirty" => !git("status", "--porcelain", "--", "lib", "config", "data", "exe").empty?,
      "elegant" => @elegant,
      "versions" => versions
    }
  end

  private

  def scope = { "BUNDLE_GEMFILE" => gemfile }

  def gemfile = File.join(@work, "Gemfile")

  def git(*arguments) = @shell.run("git", "-C", @kata, *arguments, dir: @work).stdout.strip

  def versions
    script = 'require "rubocop"; require "json"; ' \
      'puts JSON.dump(%w[rubocop rubocop-elegant rubocop-kata].to_h { [it, Gem.loaded_specs[it]&.version.to_s] })'
    JSON.parse(ruby("-e", script, dir: @work).stdout)
  end
end
