# frozen_string_literal: true

class Assay::Settings
  PROBE = File.expand_path("../probe.rb", __dir__)

  def initialize(bundle, work)
    @bundle = bundle
    @work = work
  end

  def to_h
    FileUtils.mkdir_p(@work)
    @bundle.configure(@work)
    stdout, stderr, status = @bundle.ruby(PROBE, @work, dir: @work)
    raise(Assay::Failure, "settings probe failed: #{stderr}") unless status.zero?
    JSON.parse(stdout)
  end
end
