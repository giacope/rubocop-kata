# frozen_string_literal: true

class Assay::Fleet
  def initialize(specs, jobs)
    @specs = specs
    @jobs = jobs
  end

  def results(&)
    found = lanes.map { launch(it, &) }.map { |child, reader| collect(child, reader) }.reduce({}, :merge)
    @specs.to_h { [it["name"], found.fetch(it["name"])] }
  end

  private

  def lanes = @specs.each_with_index.group_by { |_, index| index % @jobs }.values.map { it.map(&:first) }

  def launch(lane)
    reader, writer = IO.pipe
    child =
      fork do
        reader.close
        writer.write(JSON.generate(lane.to_h { [it["name"], yield(it)] }))
      end
    writer.close
    [child, reader]
  end

  def collect(child, reader)
    text = reader.read
    Process.wait(child)
    JSON.parse(text)
  end
end
