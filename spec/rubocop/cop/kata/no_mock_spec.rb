# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Kata::NoMock, :config) do
  let(:ruby_version) { 3.4 }
  let(:cop_config) { RuboCop::ConfigLoader.default_configuration.for_cop("Kata/NoMock").merge("Enabled" => true) }
  let(:advice) do
    "so the test knows which calls the object makes; pass a fake instead, a small working object with " \
      "the collaborator's interface."
  end

  def mock(label, kind) = "`#{label}` #{kind}, #{advice}"

  # V1 P13: only `double` was flagged, by RSpec/VerifiedDoubles, whose advice is another mock.
  it "reports RSpec's doubles, stubs, expectations and spies" do
    expect_offense(<<~RUBY)
      it "greets in the afternoon" do
        clock = instance_double(Shop::Clock, now: Time.utc(2024, 1, 1, 15))
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{mock("instance_double", "builds a mock")}
        other = double("clock", now: 1)
                ^^^^^^^^^^^^^^^^^^^^^^^ #{mock("double", "builds a mock")}
        allow(Time).to receive(:now).and_return(Time.utc(2024, 1, 1, 15))
                       ^^^^^^^^^^^^^ #{mock("receive", "stubs a message")}
        expect(described_class.new(clock).text).to eq("Good afternoon")
        expect(clock).to have_received(:now).once
                         ^^^^^^^^^^^^^^^^^^^ #{mock("have_received", "expects a message")}
        expect(other).not_to(receive(:hour))
                             ^^^^^^^^^^^^^^ #{mock("receive", "expects a message")}
        allow_any_instance_of(Shop::Cart).to receive_messages(total: 1)
                                             ^^^^^^^^^^^^^^^^^^^^^^^^^^ #{mock("receive_messages", "stubs a message")}
        logger = spy("logger")
                 ^^^^^^^^^^^^^ #{mock("spy", "builds a mock")}
      end
    RUBY
  end

  it "reports Minitest's mock and stub, mocha's, and RSpec's older syntax" do
    expect_offense(<<~RUBY, "test/shop/greeting_test.rb")
      clock = Minitest::Mock.new
              ^^^^^^^^^^^^^^^^^^ #{mock("Minitest::Mock", "builds a mock")}
      clock.expect(:now, Time.utc(2024, 1, 1, 9))
      Time.stub(:now, Time.utc(2024, 1, 1, 9)) { greeting.text }
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{mock("stub", "stubs a message")}
      cart = mock("cart")
             ^^^^^^^^^^^^ #{mock("mock", "builds a mock")}
      cart.expects(:total).returns(1)
      ^^^^^^^^^^^^^^^^^^^^ #{mock("expects", "expects a message")}
      Shop::Cart.any_instance.stubs(:total).returns(2)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{mock("stubs", "stubs a message")}
      order.stub(total: 3)
      ^^^^^^^^^^^^^^^^^^^^ #{mock("stub", "stubs a message")}
      order.should_receive(:pay)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^ #{mock("should_receive", "expects a message")}
    RUBY
  end

  it "passes a fake, and the words a mock library uses for other things" do
    expect_no_offenses(<<~RUBY, "spec/shop/greeting_spec.rb")
      it "greets in the morning" do
        clock = Shop::FakeClock.new(Time.utc(2024, 1, 1, 9))
        expect(described_class.new(clock).text).to eq("Good morning")
        expect(socket.receive(1024)).to eq("pong")
        expect { inbox.receive(mail) }.to change(inbox, :size)
        expect(Shop::Order).to respond_to(:receive)
        stub_const("Shop::LIMIT", 2)
        matcher = receive(:pong)
        expect(mailbox.process(receive(:mail))).to be(true)
        order.stub
      end
    RUBY
  end

  # sshkit: `@output = stub()` builds an empty mocha stub.
  it "reports a bare stub or mock built with no arguments, unless the spec names one so" do
    expect_offense(<<~RUBY, "test/unit/test_color.rb")
      output = stub()
               ^^^^^^ #{mock("stub", "builds a mock")}
    RUBY
  end

  it "leaves a let or subject the spec names stub or mock" do
    expect_no_offenses(<<~RUBY, "spec/shop/order_spec.rb")
      let(:stub) { Shop::FakeClock.new(1) }
      subject(:mock) { Shop::FakeClock.new(2) }
      it { expect(stub.now + mock.now).to eq(3) }
    RUBY
  end

  it "reads a message named by a string or a variable, and one is_expected receives" do
    expect_offense(<<~RUBY, "spec/shop/order_spec.rb")
      order.stub("total")
      ^^^^^^^^^^^^^^^^^^^ #{mock("stub", "stubs a message")}
      order.stubs(name)
      ^^^^^^^^^^^^^^^^^ #{mock("stubs", "stubs a message")}
      it { is_expected.to receive(:call) }
                          ^^^^^^^^^^^^^^ #{mock("receive", "expects a message")}
    RUBY
  end

  # dry-monads' do_for_spec defines its own `double`.
  it "leaves a mock builder the spec defines for itself" do
    expect_no_offenses(<<~RUBY, "spec/shop/order_spec.rb")
      def mock(name) = Shop::FakeClock.new(name)
      def double(value) = value * 2
      clock = mock("clock")
      twice = double(2)
    RUBY
  end

  context "with the project's own stubbing API" do
    include ProjectFiles

    let(:setting) { { "Kata/NoMock" => cop_config.merge("OwnedPaths" => ["lib/**/*.rb"]) } }

    # excon's tests exercise Excon.stub, which excon itself ships.
    it "leaves the library under test to its own words" do
      files = {
        "lib/excon.rb" => "module Excon\n  def self.stub(request, response) = [request, response]\nend\n",
        "test/stub_test.rb" => "Excon.stub({ method: :get }, { body: \"x\" })\nconnection.stub(:get)\n"
      }
      expect(project_offenses(files, "test/stub_test.rb")).to(be_empty)
    end
  end
end
