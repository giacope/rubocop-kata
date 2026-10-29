# frozen_string_literal: true

class Assay::Gate
  LIMITS = File.expand_path("../../gate.yml", __dir__)

  def initialize(data)
    @data = data
  end

  def check(io)
    breaches.each { io.puts("gate: #{it}") }
    breaches.empty? ? 0 : 1
  end

  private

  def breaches = @_breaches ||= [*%w[cases cli].flat_map { cases(it) }, *names]

  def cases(section) = @data.dig(section, "results").to_a.flat_map { verdict(it) }

  def verdict(row)
    return row["passed"] ? ["#{row["id"]} passes now; drop its `known` mark"] : [] if row["known"]
    row["passed"] ? [] : ["#{row["id"]}: #{row["faults"].join("; ")}"]
  end

  def names
    return [] unless @data.key?("names")
    YAML.safe_load_file(LIMITS).fetch("names").flat_map do |variant, splits|
      splits.flat_map { |split, bound| worse(@data.dig("names", variant, split), "#{variant} #{split}", bound) }
    end
  end

  def worse(score, label, bound)
    [
      ("#{label}: #{score["fp"]} false positives, more than #{bound["fp"]}" if score["fp"] > bound["fp"]),
      ("#{label}: recall #{score["recall"]}, below #{bound["recall"]}" if score["recall"] < bound["recall"])
    ].compact
  end
end
