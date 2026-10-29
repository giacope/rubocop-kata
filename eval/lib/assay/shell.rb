# frozen_string_literal: true

class Assay::Shell
  def initialize(env)
    @env = env
  end

  def run(*command, dir:, env: {})
    stdout, stderr, status = Open3.capture3(@env.merge(env), *command, chdir: dir, unsetenv_others: true)
    [stdout, stderr, status.exitstatus]
  end

  def with(extra) = self.class.new(@env.merge(extra))
end
