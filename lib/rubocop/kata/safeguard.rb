# frozen_string_literal: true

module RuboCop::Kata::Safeguard
  private

  def finalize_corrections(file, original_source, corrected_source)
    flaw = scrutiny(original_source, corrected_source || @options[:stdin])
    return super unless flaw
    Kernel.warn("rubocop-kata: kept #{RuboCop::PathUtil.smart_path(file)} as it was: -a would have #{flaw}")
    @options[:stdin] &&= original_source
    super(file, original_source, nil)
  end

  def scrutiny(original, corrected)
    RuboCop::Kata::Correction.new(original, corrected).flaw if @options[:safe_autocorrect] && corrected
  end
end
