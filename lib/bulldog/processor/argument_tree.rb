module Bulldog
  module Processor
    class ArgumentTree
      def initialize(styles)
        @styles = styles
        @root = Node.new(styles)
        @heads = {}
        styles.each{|s| @heads[s] = @root}
      end

      attr_reader :styles, :root, :heads

      def add(style, arguments, &callback)
        # Assume that if the arguments are the same for a node, the
        # callback will be identical.
        child = heads[style].children.find do |node|
          node.arguments == arguments
        end
        if child
          child.styles << style
        else
          child = Node.new([style], arguments, &callback)
          heads[style].children << child
        end
        heads[style] = child
      end

      def output(style, path)
        heads[style].outputs << path
      end

      def inspect
        io = StringIO.new
        inspect_node(io, @root)
        io.string
      end

      #
      # Return the list of arguments the tree represents.
      #
      def arguments
        arguments = visit_node_for_arguments([], root, false)
        # Don't specify -write for the last output file.
        arguments[-2] == '-write' or
          raise "[BULLDOG BUG]: expected second last argument to be -write in: #{arguments.inspect}"
        arguments.delete_at(-2)
        arguments
      end

      #
      # Yield each callback, along with the styles they apply to, in
      # the order they appear in the tree.
      #
      def each_callback(&block)
        visit_node_for_callbacks(root, block)
      end

      private  # ---------------------------------------------------

      def inspect_node(io, node, margin='')
        puts "#{margin}* #{node.styles.map(&:name).join(', ')}: #{node.arguments.join(' ')}"
        node.children.each do |child|
          inspect_node(io, child, margin + '  ')
        end
      end

      def visit_node_for_arguments(arguments, node, clone)
        if clone
          arguments << '(' << '+clone'
          visit_node_for_arguments(arguments, node, false)
          arguments << '+delete' << ')'
        else
          arguments.concat(node.arguments)
          node.outputs.each{|path| arguments << '-write' << path}

          num_children = node.children.size
          node.children.each_with_index do |child, i|
            # No need to clone the image for the last child.
            visit_node_for_arguments(arguments, child, i < num_children - 1)
          end
        end
        arguments
      end

      def visit_node_for_callbacks(node, block)
        if node.callback
          block.call(node.styles, node.callback)
        end
        node.children.each do |child|
          visit_node_for_callbacks(child, block)
        end
      end

      class Node
        def initialize(styles, arguments=[], &callback)
          @styles = styles
          @arguments = arguments
          @callback = callback
          @outputs = []
          @children = []
        end

        def add_child(child)
          children << child
        end

        def remove_child(child)
          children.delete(child)
        end

        attr_accessor :outputs
        attr_reader :styles, :arguments, :callback, :children
      end
    end
  end
end
