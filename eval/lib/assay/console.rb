# frozen_string_literal: true

class Assay::Console
  def initialize(bundle, work, source, kata)
    @bundle = bundle
    @work = work
    @source = source
    @kata = kata
  end

  def to_h
    rows = YAML.safe_load_file(@source).map { invoke(it) }
    { "total" => rows.size, "passed" => rows.count { it["passed"] }, "results" => rows }
  end

  private

  def invoke(item) = Assay::Invocation.new(@bundle, File.join(@work, item.fetch("id")), item, @kata).to_h
end
