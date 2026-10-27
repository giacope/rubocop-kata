# frozen_string_literal: true

class RuboCop::Cop::Kata::NoHardWiring < RuboCop::Cop::Base
  include RuboCop::Cop::Kata::Roster
  include RuboCop::Cop::Kata::Ownership
  include RuboCop::Cop::Kata::Ancestry

  SEAM = "take one in the constructor, with this `new` as the parameter's default."
  MSG = "`%s` builds the `%s` it talks to; #{SEAM}".freeze
  KEPT = "`%s` builds the `%s` it keeps in `%s`; #{SEAM}".freeze
  HANDED = "`%s` builds the `%s` it hands to `%s`; #{SEAM}".freeze
  CONSTRUCTORS = %i[initialize initialize_copy].freeze
  CALLS = %i[send csend].freeze
  STORES = %i[ivasgn cvasgn gvasgn].freeze
  GLOBALS = %i[const gvar cvar].freeze
  ITERATORS = %i[each each_with_index each_with_object times tap].freeze

  RESTRICT_ON_SEND = %i[new].freeze

  def on_send(node)
    method = node.each_ancestor(:def, :defs).first
    return unless method && candidate?(node, method)
    message, place = finding(node, method)
    return unless message
    add_offense(node, message: format(message, method.method_name, node.receiver.const_name, place))
  end

  private

  def candidate?(node, method)
    return false unless instance?(method) && node.each_ancestor(:optarg, :kwoptarg).none?
    target = node.receiver
    home = home(method)
    own?(target) && !owners(target).include?(home) && !root?(home)
  end

  def finding(node, method)
    built = built(node)
    holder = built.parent
    place = kept(holder)
    return [KEPT, place] if place
    wraps?(node) ? acted(built, holder, method) : wired(built, holder, method)
  end

  def acted(built, holder, method)
    [MSG] if talked?(built, holder, method) && asked(holder, method).any? { command?(it) }
  end

  def wired(built, holder, method)
    place = handed(built, holder, method)
    return [HANDED, place] if place
    [MSG] if talked?(built, holder, method)
  end

  def kept(holder)
    store = holder.or_asgn_type? ? holder.children.first : holder
    store.children.first if STORES.include?(store.type)
  end

  def handed(built, holder, method) = passed(built, holder) || relayed(holder, method)

  def passed(built, holder)
    holder = holder.parent while holder.type?(:pair, :hash)
    "#{holder.receiver.source}.new" if maker?(holder) && given(holder).any? { it.equal?(built) }
  end

  def relayed(holder, method)
    return unless holder.lvasgn_type?
    maker = method.each_node(:send).find { |call| maker?(call) && handing?(call, holder) }
    "#{maker.receiver.source}.new" if maker
  end

  def handing?(call, holder)
    call.source_range.begin_pos > holder.source_range.end_pos && given(call).any? { local?(it, holder.name) }
  end

  def maker?(call) = call.send_type? && call.method?(:new) && !call.receiver.nil?

  def given(call) = call.arguments.flat_map { it.hash_type? ? it.values : [it] }

  def wraps?(node)
    parts = node.arguments
    parts.any? { !it.recursive_basic_literal? } && parts.none? { |part| part.each_node(*GLOBALS).any? { outside?(it) } }
  end

  def outside?(part) = !part.const_type? || !part.namespace.nil? || !named?(part.short_name)

  def named?(name) = processed_source.ast.each_node(:casgn).any? { it.short_name == name }

  def asked(holder, method)
    return [holder] unless holder.lvasgn_type?
    method.each_node(*CALLS).select { local?(it.receiver, holder.name) }
  end

  def command?(call) = call.bang_method? || call.assignment_method? || discarded?(call)

  def discarded?(call)
    outer = call.parent
    return iterated?(outer, call) unless outer.begin_type?
    !outer.children.last.equal?(call) || iterated?(outer.parent, outer)
  end

  def iterated?(block, body) = block.any_block_type? && block.body.equal?(body) && ITERATORS.include?(block.method_name)

  def root?(home) = project.ancestors(home).intersect?(list("RootSuperclasses"))

  def instance?(method)
    method.def_type? && !CONSTRUCTORS.include?(method.method_name) && method.each_ancestor(:sclass).none?
  end

  def home(method) = method.each_ancestor(:class, :module).first&.then { RuboCop::Kata::Nesting.new(it).qualified }.to_s

  def talked?(built, holder, method)
    return holder.receiver.equal?(built) if CALLS.include?(holder.type)
    holder.lvasgn_type? && !product?(holder, method) && asked(holder, method).any?
  end

  def product?(holder, method)
    body = method.body
    local?(body.begin_type? ? body.children.last : body, holder.name)
  end

  def built(node)
    holder = node.parent
    holder&.any_block_type? && holder.send_node.equal?(node) ? holder : node
  end

  def local?(receiver, name) = receiver&.lvar_type? && receiver.children.first == name
end
