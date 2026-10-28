# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Kata::FailFast, :config) do
  let(:ruby_version) { 3.4 }
  let(:cop_config) do
    YAML.load_file("config/default.yml", aliases: true).fetch("Kata/FailFast").merge("Enabled" => true)
  end

  def swallow(value)
    "This `rescue` swallows the error and answers `#{value}` instead: let it raise (fail fast), or rescue " \
      "the one error you expect and answer an object that says what failed."
  end

  def logged
    "This `rescue` logs the error and swallows it: let it raise (fail fast), or rescue the one error " \
      "you expect and answer an object that says what failed."
  end

  def modifier
    "A `rescue` modifier catches every StandardError, bugs included: rescue the one error you expect, " \
      "or let it raise."
  end

  # The V1 conformance case P25: rates read from a source that may fail.
  it "flags a rescue that answers a default, logged or not" do
    expect_offense(<<~RUBY, empty: swallow("nil"), hash: swallow("{}"), zero: swallow("0"))
      class Rates
        def table
          JSON.parse(@source.read)
        rescue StandardError
        ^^^^^^ %{empty}
        end

        def cached
          JSON.parse(@source.read)
        rescue JSON::ParserError, IOError => error
        ^^^^^^ %{hash}
          @log.warn("rates unavailable: \#{error.message}")
          {}
        end

        def limit
          Integer(@source.limit) rescue 0
                                 ^^^^^^ %{zero}
        end
      end
    RUBY
  end

  it "reads every default: nil, a literal, an empty collection, a bare exit from the block" do
    expect_offense(<<~RUBY, nil: swallow("nil"), zero: swallow("0"), text: swallow('""'), list: swallow("[]"))
      def values
        [
          (begin; a; rescue KeyError; nil; end),
                     ^^^^^^ %{nil}
          (begin; a; rescue KeyError; return 0; end),
                     ^^^^^^ %{zero}
          (begin; a; rescue KeyError; ""; end),
                     ^^^^^^ %{text}
          (begin; a; rescue KeyError; break []; end),
                     ^^^^^^ %{list}
          (begin; a; rescue KeyError; next; end),
                     ^^^^^^ %{nil}
          (begin; a; rescue KeyError; {a: 1}; end)
        ]
      end
    RUBY
  end

  it "flags a rescue that only logs" do
    expect_offense(<<~RUBY, message: logged)
      def perform(id)
        Customer.find(id).sync
      rescue ActiveRecord::RecordNotFound
      ^^^^^^ %{message}
        Rails.logger.info("no customer \#{id}")
      end
    RUBY
  end

  # R6B5-K2: a log line through `&.` is the same log line.
  it "reads a log line written through safe navigation" do
    expect_offense(<<~RUBY, logged: logged, hash: swallow("{}"))
      def rates
        JSON.parse(@source.read)
      rescue JSON::ParserError => error
      ^^^^^^ %{logged}
        @log&.warn(error.message)
      end

      def cached
        JSON.parse(@source.read)
      rescue JSON::ParserError => error
      ^^^^^^ %{hash}
        @log&.warn(error.message)
        {}
      end
    RUBY
  end

  it "flags a rescue modifier whatever it answers" do
    expect_offense(<<~RUBY, message: modifier)
      def parsed = JSON.parse(@text) rescue Absent.new(@text)
                                     ^^^^^^ %{message}
    RUBY
  end

  it "passes a rescue that raises, retries or exits" do
    expect_no_offenses(<<~RUBY)
      def run
        call
      rescue Timeout::Error
        retry if (@tries += 1) < 3
        nil
      rescue IndexError
        raise if @strict
        nil
      rescue KeyError => error
        @log.warn(error.message)
        raise
      rescue ArgumentError
        fail Invalid
      rescue Interrupt
        exit(1)
      rescue SignalException
        Kernel.abort("stopped")
      end
    RUBY
  end

  it "passes a rescue that turns the error into an object, or handles it" do
    expect_no_offenses(<<~RUBY)
      def fetch(key)
        @table.fetch(key)
      rescue KeyError
        Absent.new(key)
      end

      def strip_host
        self.path = URI.parse(path).path
      rescue URI::InvalidURIError
        errors.add(:path, "is not a URL")
        false
      end

      def body
        read
      rescue IOError => error
        "unreadable: \#{error.message}"
      end

      def report
        compute
      rescue StandardError => error
        @log.info
        error
      end
    RUBY
  end

  it "passes a boolean that answers a question about the errors it names" do
    expect_no_offenses(<<~RUBY)
      def check(url)
        valid = begin
          Addressable::URI.parse(url).host.present?
        rescue Addressable::URI::InvalidURIError
          false
        end
        valid
      end

      def numeric?(id) = Integer(id, 10) rescue false

      def defines?(name)
        method(name).owner != Object
      rescue NameError
        false
      end

      def ==(other) = magnitude == other.magnitude rescue false

      def <=>(other)
        rank <=> other.rank
      rescue NoMethodError
        nil
      end
    RUBY
  end

  it "flags a boolean answered for a bug or for every error" do
    expect_offense(<<~RUBY, message: swallow("false"))
      def parts?
        edition.parts.any?
      rescue NoMethodError
      ^^^^^^ %{message}
        false
      end

      def started?
        Time.current > @start
      rescue StandardError
      ^^^^^^ %{message}
        false
      end

      def check
        valid = begin
          parse
        rescue StandardError
        ^^^^^^ %{message}
          false
        end
        valid
      end

      def flag = Integer(@text) rescue false
                                ^^^^^^ %{message}
    RUBY
  end

  it "passes the end of a stream, a process or a queue, and an optional library" do
    expect_no_offenses(<<~RUBY)
      def drain
        loop { @io.read_nonblock(10) }
      rescue EOFError, ::IOError
        nil
      end

      def stop(pid)
        Process.kill("TERM", pid)
      rescue Errno::ESRCH
      end

      def oj?
        require "oj"
        true
      rescue LoadError
        false
      end
    RUBY
  end

  it "passes a resource released on the way out" do
    expect_no_offenses(<<~RUBY)
      def connect
        @socket.write("x")
      rescue IOError => error
        @audit.record(error) rescue nil
        @socket&.close rescue nil
        raise error
      ensure
        @cache.write(:done) rescue nil
      end

      def send_line(line)
        @socket.write(line)
      rescue Errno::EPIPE => error
        response = @socket.read rescue ""
        raise IOError, "\#{response}\#{error.message}"
      end

      def reset
        @socket.close
      rescue IOError
        nil
      end
    RUBY
  end

  # R6B5-K4: excon's `reset` and its connect loop; no error is in flight there.
  it "flags a release that swallows where no error is in flight" do
    expect_offense(<<~RUBY, message: swallow("nil"))
      def reset = @socket.close rescue nil
                                ^^^^^^ %{message}

      def connect
        @addresses.each do |address|
          socket = address.open
          socket.handshake
          return socket
        rescue SystemCallError
          socket.close rescue nil
                       ^^^^^^ %{message}
          socket&.close rescue nil
                        ^^^^^^ %{message}
        end
        raise Errno::ECONNREFUSED
      end
    RUBY
  end

  it "flags a swallow in the main body of a method that also has an ensure" do
    expect_offense(<<~RUBY, message: swallow("nil"))
      def write
        begin
          @file.write("x")
        rescue KeyError
        ^^^^^^ %{message}
          nil
        end
      ensure
        @file.close
      end
    RUBY
  end

  context "with the shipped defaults" do
    let(:root) { File.expand_path("../../../..", __dir__) }
    let(:config) do
      shipped = YAML.load_file(File.join(root, "config/default.yml"), aliases: true).slice("Kata/FailFast")
      RuboCop::Config.new(shipped, File.join(root, ".rubocop.yml"))
    end

    it "leaves the test suite alone" do
      cop = described_class.new(config)
      paths = %w[spec/a_spec.rb test/a_test.rb lib/a.rb lib/tasks/a.rake]
      expect(paths.select { cop.relevant_file?(File.join(root, it)) }).to(eq(%w[lib/a.rb lib/tasks/a.rake]))
    end
  end
end
