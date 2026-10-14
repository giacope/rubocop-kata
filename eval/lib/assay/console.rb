# frozen_string_literal: true

class Assay::Console
  def initialize(bundle, work, source)
    @bundle = bundle
    @work = work
    @source = source
  end

  def to_h
    rows = YAML.safe_load_file(@source).map { invoke(it) }
    { "total" => rows.size, "passed" => rows.count { it["passed"] }, "results" => rows }
  end

  private

  def invoke(item) = Assay::Invocation.new(@bundle, File.join(@work, item.fetch("id")), item).to_h
end
