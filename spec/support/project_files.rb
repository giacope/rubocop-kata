# frozen_string_literal: true

require "tmpdir"

module ProjectFiles
  def project_offenses(files, path)
    Dir.mktmpdir("kata-project") do |root|
      files.each { |name, text| written(root, name, text) }
      config = RuboCop::Config.new(setting, File.join(root, ".rubocop.yml"))
      parsed = RuboCop::ProcessedSource.new(files.fetch(path), 3.4, File.join(root, path))
      RuboCop::Cop::Commissioner.new([described_class.new(config)], [], raise_error: true).investigate(parsed).offenses
    end
  end

  def written(root, name, text)
    FileUtils.mkdir_p(File.dirname(File.join(root, name)))
    File.write(File.join(root, name), text)
  end
end
