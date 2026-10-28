# frozen_string_literal: true

module RuboCop::Cop::Kata::Fabrication
  include RuboCop::Cop::Kata::Memoization
  include RuboCop::Cop::Kata::Answer

  KERNEL = %i[require require_relative load autoload puts print p pp warn printf putc exit abort sleep].freeze
  MUTATORS = %i[<< []= add push append unshift concat delete store clear replace pop shift].freeze
  SILENT = %i[raise fail].freeze
  STATE = %i[ivasgn cvasgn gvasgn].freeze
  LOOPS = %i[each each_with_index each_pair each_key each_value times upto downto loop].freeze
  PHRASE = /\A(?:by|for|from|with|without|in|into|on|at|to|of|or|and|as|via|if|unless|all)(?:_|\z)/
  COMPOUND = /(?:\A|_)and_|(?:\A|_)params\z/
  CALLBACK = /\A(?:before|after|around)_|\Avalidate\z/

  private

  def crafted(node, name)
    return unless cop_config["CheckEveryBuilder"] && !name.end_with?("!", "=")
    verb = list("BuilderPrefixes").find { name.start_with?("#{it}_") }
    verb if verb && built?(node, name.delete_prefix("#{verb}_"))
  end

  def built?(node, noun) = !COMPOUND.match?(noun) && !named?(node) && fabricates?(node) && free?(node, noun)

  def named?(node) = hooked?(node) || kept?(node)

  def kept?(node)
    field = :"@#{node.method_name}"
    node.each_descendant(:ivar, :ivasgn).any? { it.children.first == field }
  end

  def hooked?(node)
    name = node.method_name
    node.each_ancestor(:class, :module).first&.each_descendant(:send, :alias)&.any? { called?(it, name) }
  end

  def called?(found, name)
    return found.children[1].value == name if found.alias_type?
    named = found.arguments.select(&:sym_type?).map(&:value)
    return named.last == name if found.method?(:alias_method)
    callback?(found) && named.include?(name)
  end

  def callback?(call) = call.receiver.nil? && CALLBACK.match?(call.method_name.to_s)

  def phrase?(noun) = PHRASE.match?(noun)

  def fabricates?(node)
    body = node.body
    return false if body.nil? || idle?(tail(body))
    body.each_node(*STATE, :send, :csend).none? { acts?(it, node) } && discarded(body).none? { ordered?(it, node) }
  end

  def discarded(body) = body.begin_type? ? body.children[0...-1].flat_map { statements(it) } : []

  def ordered?(call, method)
    name = call.method_name
    !(SILENT.include?(name) || LOOPS.include?(name) || answer?(call) || made?(call.receiver, method))
  end

  def idle?(value)
    return true if value.nil_type?
    call = value.any_block_type? ? value.send_node : value
    call.call_type? && LOOPS.include?(call.method_name)
  end

  def acts?(found, method)
    return !memoized?(found) if STATE.include?(found.type)
    name = found.method_name
    return true if listed?("Effects", name.to_s) || (found.receiver.nil? && KERNEL.include?(name))
    altering?(found) && !made?(found.receiver, method)
  end

  def altering?(call)
    name = call.method_name
    MUTATORS.include?(name) || call.bang_method? || call.setter_method?
  end

  def made?(receiver, method)
    receiver&.lvar_type? && method.arguments.none? { it.name == receiver.children.first }
  end

  def free?(node, noun)
    scope = node.each_ancestor(:class, :module).first
    return processed_source.ast.each_node(:def).none? { it.method?(noun.to_sym) } unless scope
    !answers?(RuboCop::Kata::Nesting.new(scope).qualified, noun, static?(node))
  end

  def answers?(owner, noun, static) = static ? project.singleton?(owner, noun) : project.instance?(owner, noun)
end
