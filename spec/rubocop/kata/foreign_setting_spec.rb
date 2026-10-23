# frozen_string_literal: true

RSpec.describe(RuboCop::Kata::ForeignSetting) do
  include TabledCop

  let(:cop) { RuboCop::Cop::Style::ClassVars.new(RuboCop::Config.new) }

  # kimera disarms Minitest's at_exit through its own class variable.
  it "reports the project's own class variables, not another class's setting" do
    own = "class Counter\n  @@count = 0\n  class_variable_set(:@@seen, 1)\n  self.class_variable_set(:@@kept, 1)\nend\n"
    source = "#{own}Minitest.class_variable_set(:@@installed_at_exit, :installed)\nrunner.class_variable_set(:@@x, 1)\n"
    expect(offenses(source).map(&:line)).to(eq([2, 3, 4]))
  end
end
