# frozen_string_literal: true

module RuboCop::Cop::Kata::Reopening
  OWNED = %w[app/**/*.rb */app/**/*.rb lib/**/*.rb */lib/**/*.rb].freeze

  private

  def judged?(node)
    name = qualified(node)
    openings = RuboCop::Kata::Inventory.of(base, cop_config.fetch("OwnedPaths", OWNED)).openings(name)
    found = openings.find { |_, path, line| line == node.first_line && here?(path) }
    found.nil? || chosen(openings, name).equal?(found)
  end

  def here?(path) = File.expand_path(path, base) == File.expand_path(processed_source.file_path.to_s, base)

  def chosen(openings, name)
    file = "/#{name.downcase.gsub("::", "/").delete("_")}.rb"
    named = openings.select { |_, path, _| "/#{path.downcase.delete("_")}".end_with?(file) }
    return named.min_by { |_, path, line| [path, line] } unless named.empty?
    openings.min_by { |_, path, line, statements| [-statements, path, line] }
  end

  def base = config.base_dir_for_path_parameters

  def qualified(node) = RuboCop::Kata::Nesting.new(node).qualified
end
