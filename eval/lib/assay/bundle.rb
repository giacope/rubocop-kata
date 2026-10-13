# frozen_string_literal: true

class Assay::Bundle
  GEMFILE = <<~RUBY
    source "https://rubygems.org"

    gem "rubocop-kata", path: %s
    gem "rubocop-elegant", %s
  RUBY
  PROBE = 'require "rubocop"; require "json"; ' \
    "puts JSON.dump(%w[rubocop rubocop-elegant rubocop-kata].to_h { [it, Gem.loaded_specs[it]&.version.to_s] })"

  attr_reader :kata

  def initialize(kata, work, shell, elegant:)
    @kata = kata
    @work = work
    @shell = shell
    @elegant = elegant
  end

  def prepare
    FileUtils.mkdir_p(@work)
    File.write(gemfile, format(GEMFILE, @kata.inspect, @elegant.inspect))
    outcome = @shell.run("bundle", "install", "--local", "--quiet", dir: @work, env: scope)
    raise(Assay::Failure, "bundle install failed: #{outcome.stderr}#{outcome.stdout}") unless outcome.status.zero?
    self
  end

  def rubocop(*, dir:) = shell.run("bundle", "exec", "rubocop", *, dir: dir)

  def ruby(*, dir:, env: {}) = shell.run("bundle", "exec", "ruby", *, dir: dir, env: env)

  def shell = @shell.with(scope)

  def to_h
    {
      "path" => @kata, "commit" => git("rev-parse", "HEAD"),
      "dirty" => !git("status", "--porcelain", "--", "lib", "config", "data", "exe").empty?,
      "elegant" => @elegant, "versions" => JSON.parse(ruby("-e", PROBE, dir: @work).stdout)
    }
  end

  private

  def scope = { "BUNDLE_GEMFILE" => gemfile }

  def gemfile = File.join(@work, "Gemfile")

  def git(*) = @shell.run("git", "-C", @kata, *, dir: @work).stdout.strip
end
