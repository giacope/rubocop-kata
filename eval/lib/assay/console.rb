# frozen_string_literal: true

class Assay::Console
  def initialize(bundle, work, source)
    @bundle = bundle
    @work = work
    @source = source
  end

  def to_h
    rows = YAML.safe_load_file(@source).map { Assay::Invocation.new(@bundle, File.join(@work, it.fetch("id")), it).to_h }
    { "total" => rows.size, "passed" => rows.count { it["passed"] }, "results" => rows }
  end
end
