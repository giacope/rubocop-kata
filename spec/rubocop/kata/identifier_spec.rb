# frozen_string_literal: true

RSpec.describe(RuboCop::Kata::Identifier) do
  it "reads a name as callable only when a bare call to it parses as that call" do
    names = %w[formula total! for module class end if self defined? not super return 2fa value= BEGIN]
    expect(names.select { described_class.new(it).callable? }).to(eq(%w[formula total!]))
  end
end
