# frozen_string_literal: true

class Assay::Sample
  SALT = "kata-human-1"
  QUOTA = { "doer" => 16, "thing" => 16, "ambiguous" => 8 }.freeze
  EXAMPLES = %w[Parser Timer User Buyer Number Water Corner Layer Header Folder].freeze
  HEADER = <<~YAML
    # Class names for one person to label, blind. After each colon write doer,
    # thing or ambiguous, by the rule in README.md beside this file. Do not open
    # eval/names.yml, eval/cases or the cop until every name has a label.
    # Drawn by `eval/run --draw`; scored by `eval/run --kata . --only human`.
  YAML

  def initialize(source)
    @source = source
  end

  def to_s
    names = QUOTA.flat_map { |label, size| pick(data.fetch(label) - EXAMPLES, size) }
    HEADER + names.sort_by { rank(it) }.map { "#{it}:\n" }.join
  end

  private

  def pick(names, size)
    held, rest = names.sort_by { rank(it) }.partition { (Zlib.crc32(it) % 3).zero? }
    share = (size / 3.0).round
    rest.first(size - share) + held.first(share)
  end

  def rank(name) = Digest::SHA256.hexdigest("#{SALT}#{name}")

  def data = @_data ||= YAML.safe_load_file(@source)
end
