# frozen_string_literal: true

class Assay::Density
  def initialize(files, lines, counts)
    @files = files
    @lines = lines
    @counts = counts
  end

  def to_h
    {
      "files" => @files, "lines" => @lines, "offenses" => @counts.values.sum, "counts" => @counts,
      "per_kloc" => @counts.transform_values { (it * 1000.0 / @lines).round(2) }
    }
  end
end
