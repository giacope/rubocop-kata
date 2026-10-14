# frozen_string_literal: true

class Assay::Gate
  def initialize(data, limits)
    @data = data
    @limits = limits
  end

  def breaches = [*%w[cases cli].flat_map { cases(it) }, *names]

  private

  def cases(section) = @data.dig(section, "results").to_a.filter_map { verdict(it) }

  def verdict(row)
    if row["known"]
      "#{row["id"]} passes now; drop its `known` mark" if row["passed"]
    else
      "#{row["id"]}: #{row["faults"].join("; ")}" unless row["passed"]
    end
  end

  def names
    return [] unless @data.key?("names")
    @limits.fetch("names").flat_map do |variant, splits|
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
