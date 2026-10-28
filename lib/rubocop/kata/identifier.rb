# frozen_string_literal: true

class RuboCop::Kata::Identifier
  def initialize(text)
    @text = text
  end

  def callable?
    call = RuboCop::ProcessedSource.new("#{@text}(value)", 3.4).ast
    call&.send_type? && call.receiver.nil? && call.method?(@text.to_sym)
  end
end
