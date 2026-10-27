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
  ESCAPES = %i[send csend super yield return].freeze
  COLLECTED = %i[pair hash array].freeze

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
    home = method.each_ancestor(:class, :module).first&.then { RuboCop::Kata::Nesting.new(it).qualified }.to_s
    own?(target) && !owners(target).include?(home) && !root?(home)
  end

  def finding(node, method)
    built = blocked(node)
    built = blocked(built.parent) if tapped?(built)
    holder = built.parent
    store = holder.or_asgn_type? ? holder.children.first : holder
    return [KEPT, store.children.first] if STORES.include?(store.type)
    wired(node, built, method)
  end

  def wired(node, built, method)
    holder = built.parent
    wrapper = wraps?(node)
    found = maker(built, holder, method) unless wrapper
    return [HANDED, "#{found.receiver.source}.new"] if found
    [MSG] if talked?(built, holder, method) && (!wrapper || asked(holder, method).any? { command?(it) })
  end

  def maker(built, holder, method)
    outer = holder
    outer = outer.parent while outer.type?(:pair, :hash)
    return outer if maker?(outer) && given(outer).any? { it.equal?(built) }
    method.each_node(:send).find { |call| maker?(call) && handing?(call, holder) } if holder.lvasgn_type?
  end

  def handing?(call, holder)
    after?(call, holder) && given(call).any? { local?(it, holder.name) }
  end

  def blocked(call)
    outer = call.parent
    outer.any_block_type? && outer.send_node.equal?(call) ? outer : call
  end

  def tapped?(built)
    call = built.parent
    call.send_type? && call.method?(:tap) && call.receiver.equal?(built)
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
    method.each_node(*CALLS).select { local?(it.receiver, holder.name) && after?(it, holder) }
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

  def talked?(built, holder, method)
    return holder.receiver.equal?(built) if CALLS.include?(holder.type)
    holder.lvasgn_type? && !product?(holder, method) && asked(holder, method).any?
  end

  def product?(holder, method)
    local?(method.body.children.last, holder.name) || method.each_node(:lvar).any? { handed?(it, holder) }
  end

  def handed?(use, holder)
    outer = use.parent
    return false unless local?(use, holder.name) && after?(use, holder) && !outer.receiver.equal?(use)
    outer = outer.parent while COLLECTED.include?(outer.type)
    ESCAPES.include?(outer.type)
  end

  def after?(node, holder) = node.first_line > holder.last_line

  def local?(receiver, name) = receiver&.lvar_type? && receiver.children.first == name
end
