# frozen_string_literal: true

class Assay::Settings
  PROBE = File.expand_path("../probe.rb", __dir__)

  def initialize(bundle, work)
    @bundle = bundle
    @work = work
  end

  def result
    FileUtils.mkdir_p(@work)
    File.write(File.join(@work, ".rubocop.yml"), Assay::Snippets::CONFIG)
    outcome = @bundle.ruby(PROBE, @work, dir: @work)
    raise "settings probe failed: #{outcome.stderr}" unless outcome.status.zero?
    JSON.parse(outcome.stdout)
  end
end
