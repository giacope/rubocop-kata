# frozen_string_literal: true

class RuboCop::Cop::Kata::IoDiscipline < RuboCop::Cop::Base
  include RuboCop::Cop::Kata::BootLayer
  include RuboCop::Cop::Kata::Roster
  include RuboCop::Cop::Kata::Ownership

  MSG = "Write through the injected `%s`, not bare `%s`."
  SEAM_MSG = "Inject the stream `%s` writes to (`def initialize(io: %s)`) and write through it."
  FIXED_MSG = "`%s` reaches a %s written into the code: hidden I/O. Inject the %s, or the object that " \
    "reaches it, and act through that."
  GLOBAL_MSG = "Inject `%s` (`def initialize(%s: %s)`) and send through it; a global reached from a method " \
    "is hidden I/O."
  STREAMS = %i[@io @out @output @stdout @stderr @stream @err @error].freeze
  ELEMENTS = %i[p print printf].freeze
  PRINTS = %i[print printf].freeze
  SEAMS = %i[ivar lvar self].freeze
  COMMAND = "command"
  PLACES = %i[base chdir].freeze

  def_node_matcher :bare_output?, "(send nil? ${:puts :warn :pp :p :print :printf} ...)"

  def on_send(node)
    bare_output?(node) do |method|
      return add_offense(node, message: message(node, method)) unless exempt?(node, method)
    end
    return unless effects?
    global(node, "#{node.receiver&.const_name}.#{node.method_name}")
    effect(node)
  end

  def on_gvar(node) = effects? && global(node, node.source)

  def on_const(node) = effects? && global(node, node.const_name)

  def on_xstr(node)
    return unless effects? && !seam?(node)
    reach(node, "%x(#{node.each_child_node(:str).first&.value.to_s[/\S+/]})", COMMAND, node.children)
  end

  private

  def message(node, method)
    held = stream(node)
    return format(MSG, held, method) if held
    format(SEAM_MSG, method, method == :warn ? "$stderr" : "$stdout")
  end

  def stream(node)
    scope = node.each_ancestor(:class, :module).first
    scope ? scope.each_descendant(:ivasgn).map { it.children.first }.find { STREAMS.include?(it) } : nil
  end

  def effects? = cop_config["CheckEffects"]

  def quiet?(method) = PRINTS.include?(method) && !effects?

  def exempt?(node, method) = element?(node) || seam?(node) || quiet?(method) || answers?(node)

  def answers?(node)
    caller = node.each_ancestor(:def, :defs).first
    return false unless caller
    home = place(caller)
    (home.first || processed_source.ast).each_descendant(:def, :defs).any? do |method|
      method.method?(node.method_name) && place(method) == home
    end
  end

  def place(method)
    scope = method.each_ancestor(:class, :module, :sclass).first
    return [scope, method.defs_type?] unless scope&.sclass_type?
    [scope.each_ancestor(:class, :module).first, true]
  end

  def element?(node) = ELEMENTS.include?(node.method_name) && (!node.arguments? || !node.block_node.nil?)

  def global(node, name)
    return unless listed?("Globals", name) && !seam?(node)
    held = node.send_type? ? node.method_name : :io
    add_offense(node, message: format(GLOBAL_MSG, node.source, held, node.source))
  end

  def effect(node)
    names = labels(node)
    return if names.empty? || listed?("AllowedMethods", names.first) || seam?(node)
    noun = names.lazy.filter_map { kind(it) }.first
    reach(node, names.first, noun, noun == COMMAND ? node.arguments : places(node)) if noun
  end

  def places(node)
    pairs = node.arguments.select(&:hash_type?).flat_map(&:pairs)
    [*node.arguments.first(1), *pairs.select { it.key.sym_type? && PLACES.include?(it.key.value) }.map(&:value)]
  end

  def reach(node, call, noun, targets)
    return if targets.any? { injected?(it) }
    add_offense(node, message: format(FIXED_MSG, call, noun, noun))
  end

  def labels(node)
    name = node.method_name
    receiver = node.receiver
    return node.arguments? && !answered?(name) ? [name.to_s] : [] if receiver.nil?
    receiver.const_type? && !own?(receiver) ? ["#{receiver.const_name}.#{name}", receiver.const_name] : []
  end

  def kind(name) = cop_config.fetch("Effects", {}).find { |_, names| Array(names).include?(name) }&.first

  def injected?(target)
    target.each_node.any? do |part|
      SEAMS.include?(part.type) || source?(part) || helper?(part) || constant?(part)
    end
  end

  def source?(part) = part.str_type? && part.source == "__FILE__"

  def helper?(part) = part.send_type? && part.receiver.nil? && !listed?("Conversions", part.method_name.to_s)

  def constant?(part)
    return false unless part.const_type? && !qualifier?(part)
    value = processed_source.ast.each_node(:casgn).find { it.short_name == part.short_name }&.expression
    value.nil? || injected?(value)
  end

  def qualifier?(part)
    holder = part.parent
    holder&.const_type? || (holder&.send_type? && holder.receiver.equal?(part))
  end
end
