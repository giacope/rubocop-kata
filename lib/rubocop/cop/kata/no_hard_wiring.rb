# frozen_string_literal: true

class RuboCop::Cop::Kata::NoHardWiring < RuboCop::Cop::Base
  include RuboCop::Cop::Kata::Roster
  include RuboCop::Cop::Kata::Ownership
  include RuboCop::Cop::Kata::Ancestry
  include RuboCop::Cop::Kata::Answer

  MSG = "`%s` builds the `%s` it talks to; take one in the constructor, with this `new` as the parameter's default."
  CONSTRUCTORS = %i[initialize initialize_copy].freeze
  CALLS = %i[send csend].freeze

  RESTRICT_ON_SEND = %i[new].freeze

  def on_send(node)
    method = node.each_ancestor(:def, :defs).first
    return unless method && wired?(node, method)
    add_offense(node, message: format(MSG, method.method_name, node.receiver.const_name))
  end

  private

  def wired?(node, method)
    return false unless instance?(method) && node.each_ancestor(:optarg, :kwoptarg).none?
    target = node.receiver
    home = home(method)
    own?(target) && !owners(target).include?(home) && !root?(home) && talked?(node, method) && !relayed?(node, method)
  end

  def relayed?(node, method)
    holder = built(node).parent
    holder.send_type? && holder.method?(method.method_name) && holder.equal?(tail(method.body)) &&
      node.arguments.any?(&:ivar_type?) && node.arguments.all? { it.type?(:ivar, :str, :sym, :int, :float, :array) }
  end

  def root?(home) = project.ancestors(home).intersect?(list("RootSuperclasses"))

  def instance?(method)
    method.def_type? && !CONSTRUCTORS.include?(method.method_name) && method.each_ancestor(:sclass).none?
  end

  def home(method) = method.each_ancestor(:class, :module).first&.then { RuboCop::Kata::Nesting.new(it).qualified }.to_s

  def talked?(node, method)
    built = built(node)
    holder = built.parent
    return false unless holder
    return holder.receiver.equal?(built) if CALLS.include?(holder.type)
    holder.lvasgn_type? && method.each_node(*CALLS).any? { local?(it.receiver, holder.children.first) }
  end

  def built(node)
    holder = node.parent
    holder&.any_block_type? && holder.send_node.equal?(node) ? holder : node
  end

  def local?(receiver, name) = receiver&.lvar_type? && receiver.children.first == name
end
