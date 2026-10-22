# frozen_string_literal: true

seen = Set.new
reach =
  lambda do |held|
    next unless seen.add?(held)
    held.constants.each do |name|
      found =
        begin
          held.const_get(name)
        rescue StandardError, ScriptError
          next
        end
      reach.call(found) if found.is_a?(Module) && found.name.to_s.start_with?("#{held.name}::")
    end
  end
%w[ActiveSupport ActiveModel ActiveRecord ActionController ActionDispatch AbstractController ActionView].each do |name|
  reach.call(Object.const_get(name)) if Object.const_defined?(name)
end
