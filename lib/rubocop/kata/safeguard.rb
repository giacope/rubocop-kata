# frozen_string_literal: true

module RuboCop::Kata::Safeguard
  KEPT = "rubocop-kata: kept %s as it was: -a would have %s (refused: %s)"

  def run(...)
    @options[:safe_autocorrect] = safe? if @options[:autocorrect]
    super
  end

  private

  def safe? = @options.fetch(:safe_autocorrect) { !@options[:autocorrect_all] }

  def do_inspection_loop(file, *)
    inspected = super
    flaws = scrutiny(@options[:stdin] || File.binread(file), inspected.first.raw_source)
    flaws.empty? ? inspected : kept(file, flaws.first, inspected.last)
  end

  def finalize_corrections(file, original_source, corrected_source)
    pending = corrected_source || @options[:stdin]
    written = File.binread(file) unless pending
    return super if scrutiny(original_source, pending || written).empty?
    @options[:stdin] &&= original_source
    super(file, original_source, written && original_source)
  end

  def scrutiny(original, corrected)
    @options[:safe_autocorrect] && corrected ? RuboCop::Kata::Correction.new(original, corrected).flaws : []
  end

  def kept(file, flaw, offenses)
    refused = offenses.select(&:corrected?).map(&:cop_name).uniq.join(", ")
    Kernel.warn(format(KEPT, RuboCop::PathUtil.smart_path(file), flaw, refused))
    plainly(file)
  end

  def plainly(file)
    processed = get_processed_source(file, nil)
    config = processed.config
    team = RuboCop::Cop::Team.mobilize(mobilized_cop_classes(config), config, @options.merge(autocorrect: false))
    [processed, inspect_file(processed, team).first]
  end
end

RuboCop::Runner.prepend(RuboCop::Kata::Safeguard)
