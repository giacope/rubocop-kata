# frozen_string_literal: true

module RuboCop::Kata::Scoped
  private

  def qualified(path, scope) = path.start_with?("::") ? path.delete_prefix("::") : [*scope, path].join("::")
end
