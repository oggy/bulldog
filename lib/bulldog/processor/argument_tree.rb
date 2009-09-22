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

      def add(styles_to_arguments)
        arguments_to_styles = Hash.new{|h,k| h[k] = []}
        styles_to_arguments.each do |style, arguments|
          arguments_to_styles[Array(arguments)] << style
        end
        arguments_to_styles.each do |arguments, styles|
          add_for_styles(styles, arguments)
        end
      end

      private  # ---------------------------------------------------

      def add_for_styles(styles, arguments)
        heads_for_styles(styles).each do |head|
          head.arguments.concat(arguments)
        end
      end

      def heads_for_styles(styles)
        heads = []
        remaining_styles = styles.uniq
        until remaining_styles.empty?
          head = @heads[remaining_styles.first]

          # find all the styles we want in the head
          wanted = remaining_styles & head.styles
          remaining_styles -= wanted

          # split head if we don't want all of them
          if wanted.size < head.styles.size
            wanted_child = Node.new(wanted)
            unwanted_child = Node.new(head.styles - wanted)
            head.children << wanted_child << unwanted_child
            wanted_child.styles.each{|c| @heads[c] = wanted_child}
            unwanted_child.styles.each{|c| @heads[c] = unwanted_child}
            heads << wanted_child
          else
            heads << head
          end
        end
        heads
      end

      class Node
        def initialize(styles, arguments=[])
          @styles = styles
          @arguments = arguments
          @children = []
        end

        attr_reader :styles, :arguments, :children
      end
    end
  end
end
