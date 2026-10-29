# frozen_string_literal: true

class Assay::Bundle
  GEMFILE = <<~RUBY
    source "https://rubygems.org"

    gem "rubocop-kata", path: %s
    gem "rubocop-elegant", %s
  RUBY
  CONFIG = "plugins:\n  - rubocop-kata\n\nAllCops:\n  TargetRubyVersion: 3.4\n  SuggestExtensions: false\n"
  PROBE = 'require "rubocop"; require "json"; ' \
    "puts JSON.dump(%w[rubocop rubocop-elegant rubocop-kata].to_h { [it, Gem.loaded_specs[it]&.version.to_s] })"

  def initialize(kata, work, shell, elegant:)
    @kata = kata
    @work = work
    @shell = shell
    @elegant = elegant
  end

  def prepare
    FileUtils.mkdir_p(home)
    File.write(gemfile, format(GEMFILE, @kata.inspect, @elegant.inspect))
    stdout, stderr, status = @shell.run("bundle", "install", "--local", "--quiet", dir: home, env: scope)
    raise(Assay::Failure, "bundle install failed: #{stderr}#{stdout}") unless status.zero?
    self
  end

  def rubocop(*, dir:) = shell.run("bundle", "exec", "rubocop", *, dir: dir)

  def ruby(*, dir:, env: {}) = shell.run("bundle", "exec", "ruby", *, dir: dir, env: env)

  def configure(dir, extra = "") = File.write(File.join(dir, ".rubocop.yml"), CONFIG + extra)

  def to_h
    {
      "path" => @kata, "commit" => git("rev-parse", "HEAD"),
      "dirty" => !git("status", "--porcelain", "--", "lib", "config", "data", "exe").empty?,
      "elegant" => @elegant, "versions" => JSON.parse(ruby("-e", PROBE, dir: home).first)
    }
  end

  private

  def shell = @shell.with(scope)

  def scope = { "BUNDLE_GEMFILE" => gemfile }

  def gemfile = File.join(home, "Gemfile")

  def home = File.join(@work, "bundle")

  def git(*) = @shell.run("git", "-C", @kata, *, dir: home).first.strip
end
