# frozen_string_literal: true

module RuboCop::Cop::Kata::Lifetime
  CALLS = %i[send csend].freeze
  STORES = %i[ivasgn cvasgn gvasgn].freeze
  ITERATORS = %i[each each_with_index each_with_object times tap].freeze
  ESCAPES = %i[send csend super yield return].freeze
  COLLECTED = %i[pair hash array].freeze
  PROBES = %i[respond_to? method public_method].freeze

  private

  def built(node)
    built = blocked(node)
    tapped?(built) ? blocked(built.parent) : built
  end

  def kept(built, method)
    holder = built.parent
    stores = held(holder)
    return stores.map { it.children.first } unless stores.empty?
    holder.lvasgn_type? ? stored(holder, method) : []
  end

  def outlives?(call, method)
    built = built(call)
    return true unless kept(built, method).empty?
    maker(built, built.parent, method).any? { outlives?(it, method) }
  end

  def maker(built, holder, method)
    outer = holder
    outer = outer.parent while outer.type?(:pair, :hash)
    return [outer] if maker?(outer) && given(outer).any? { it.equal?(built) }
    return [] unless holder.lvasgn_type?
    method.each_node(*CALLS).lazy.select { |call| maker?(call) && handing?(call, holder) }.first(1)
  end

  def talked?(node, built, method)
    holder = built.parent
    return holder.receiver.equal?(built) && talk?(holder) if CALLS.include?(holder.type)
    holder.lvasgn_type? && !product?(holder, method) && !scratch?(node, holder, method) &&
      asked(holder, method).any? { talk?(it) }
  end

  def scratch?(node, holder, method)
    return false if node.arguments? || !holder.lvasgn_type?
    fills = filled(holder, method)
    asked(holder, method).any? { |read| !command?(read) && fills.any? { read.first_line > it.last_line } }
  end

  def filled(holder, method)
    asked(holder, method).select { command?(it) } + uses(holder, method).select { handed?(it) }
  end

  def held(holder)
    store = holder.or_asgn_type? ? holder.children.first : holder
    STORES.include?(store.type) ? [store] : []
  end

  def stored(holder, method) = uses(holder, method).lazy.flat_map { held(it.parent) }.first(1).map { it.children.first }

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

  def maker?(call) = call.call_type? && call.method?(:new) && !call.receiver.nil?

  def given(call) = call.arguments.flat_map { it.hash_type? ? it.values : [it] }

  def talk?(call) = !PROBES.include?(call.method_name)

  def asked(holder, method)
    method.each_node(*CALLS).select { local?(it.receiver, holder.name) && after?(it, holder) }
  end

  def command?(call) = call.bang_method? || call.assignment_method? || discarded?(call)

  def discarded?(call)
    outer = call.parent
    return iterated?(outer, call) unless outer.begin_type?
    !outer.children.last.equal?(call) || iterated?(outer.parent, outer)
  end

  def iterated?(block, body) = block.any_block_type? && block.body.equal?(body) && ITERATORS.include?(block.method_name)

  def product?(holder, method) = uses(holder, method).any? { answer?(it) || handed?(it) }

  def uses(holder, method) = method.each_node(:lvar).select { local?(it, holder.name) && after?(it, holder) }

  def answer?(use)
    outer = use.parent
    outer = outer.parent if outer.begin_type? && outer.children.last.equal?(use)
    outer.type?(:def, :defs, :any_block)
  end

  def handed?(use)
    outer = use.parent
    return false if outer.receiver.equal?(use)
    outer = outer.parent while COLLECTED.include?(outer.type)
    ESCAPES.include?(outer.type)
  end

  def after?(node, holder) = node.first_line > holder.last_line

  def local?(receiver, name) = receiver&.lvar_type? && receiver.children.first == name
end
