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

      def add(style, arguments)
        child = heads[style].children.find do |node|
          node.arguments == arguments
        end
        if child
          child.styles << style
        else
          child = Node.new([style], arguments)
          heads[style].children << child
        end
        heads[style] = child
      end

      def inspect
        io = StringIO.new
        inspect_node(io, @root)
        io.string
      end

      private  # ---------------------------------------------------

      def inspect_node(io, node, margin='')
        puts "#{margin}* #{node.styles.map(&:name).join(', ')}: #{node.arguments.join(' ')}"
        node.children.each do |child|
          inspect_node(io, child, margin + '  ')
        end
      end

      class Node
        def initialize(styles, arguments=[])
          @parent = nil
          @styles = styles
          @arguments = arguments
          @children = []
        end

        def add_child(child)
          children << child
          child.parent = self
        end

        def remove_child(child)
          children.delete(child)
        end

        attr_accessor :parent
        attr_reader :styles, :arguments, :children
      end
    end
  end
end
