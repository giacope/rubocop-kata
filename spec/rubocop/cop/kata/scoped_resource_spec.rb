# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Kata::ScopedResource, :config) do
  let(:ruby_version) { 3.4 }

  def held(acquired, release)
    "`#{acquired}` is released by `#{release}` outside an `ensure`: an exception between them never releases " \
      "it. Hold it for a block (`synchronize { ... }`, `File.open(path) { ... }`) or release it in `ensure`."
  end

  # The V1 conformance case P27: an archive that takes a lock by hand.
  it "flags a lock taken and released by hand" do
    expect_offense(<<~RUBY, lock: held("@lock.lock", "@lock.unlock"), pool: held("pool.checkout", "pool.checkin"))
      class Archive
        def append(line)
          @lock.lock
          ^^^^^^^^^^ %{lock}
          @log.write(line)
          @lock.unlock
        end

        def self.borrow(pool)
          pool.checkout
          ^^^^^^^^^^^^^ %{pool}
          yield
          pool.checkin
        end
      end
    RUBY
  end

  # mechanize's Mechanize.start: `instance.shutdown` never runs when the block raises.
  it "flags a handle opened into a local and closed by hand" do
    messages = { socket: held("TCPSocket.new(@host, 80)", "socket.close"), agent: held("new", "agent.shutdown") }
    expect_offense(<<~RUBY, **messages)
      class Client
        def ping
          socket = TCPSocket.new(@host, 80)
                   ^^^^^^^^^^^^^^^^^^^^^^^^ %{socket}
          socket.write("ping")
          socket.close
        end

        def self.start
          agent = new
                  ^^^ %{agent}
          yield agent
          agent.shutdown
        end
      end
    RUBY
  end

  it "passes a release in an ensure or a rescue, and a block that holds the resource" do
    expect_no_offenses(<<~RUBY)
      class Archive
        def append(line)
          @lock.lock
          begin
            @log.write(line)
          ensure
            @lock.unlock
          end
        end

        def ping
          socket = TCPSocket.new(@host, 80)
          socket.write("ping")
          socket
        rescue IOError
          socket.close
          raise
        end

        def guarded
          @lock.synchronize { @log.write("x") }
          File.open(@path) { it.read }
        end
      end
    RUBY
  end

  it "passes a release with nothing between it and the acquire, and an unpaired call" do
    expect_no_offenses(<<~RUBY)
      class Pool
        def drop
          if (old = @sockets.delete(@key))
            old.close
          end
        end

        def take = @lock.lock

        def other
          @lock.lock
          write
          @other.unlock
          stream = build
          stream.close
          write
        end
      end
    RUBY
  end

  it "leaves File.open and Tempfile.open to Style/FileOpen, and a value that is no call" do
    expect_no_offenses(<<~RUBY)
      def save(text)
        file = File.open(@path, "w")
        file.write(text)
        file.close
        temp = Tempfile.open("x")
        temp.write(text)
        temp.close
        name = @name
        write
        name.close
      end
    RUBY
  end
end
