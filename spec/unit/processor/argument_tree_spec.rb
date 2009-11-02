require 'spec_helper'

describe Processor::ArgumentTree do
  Tree = Processor::ArgumentTree
  Node = Processor::ArgumentTree::Node

  before do
    @a = Style.new(:a)
    @b = Style.new(:b)
  end

  describe "initially" do
    before do
      @tree = Tree.new(StyleSet[@a, @b])
    end

    it "should have only the root node" do
      @tree.root.should be_a(Tree::Node)
      @tree.root.children.should be_empty
    end

    it "should have all heads pointing to the root node" do
      root = @tree.root
      [@a, @b].map{|style| @tree.heads[style]}.should == [root, root]
    end
  end

  describe "#add" do
    describe "when the tree is empty" do
      before do
        @tree = Tree.new(StyleSet[@a, @b])
      end

      it "should create a new node for the given style and arguments" do
        @tree.add(@a, ['a', 'b'])
        @tree.root.children.should have(1).nodes
        @tree.root.children.first.styles.should == [@a]
        @tree.root.children.first.arguments.should == ['a', 'b']
      end
    end

    describe "when there is a node under the head for the given arguments" do
      before do
        #
        #  root --- one --- two
        #            ^       ^
        #            a       b
        #
        @tree = Tree.new(StyleSet[@a])
        @one = Node.new([@a, @b], ['one', '1'])
        @two = Node.new([@a], ['two', '2'])
        @tree.root.children << @one
        @one.children << @two
        @tree.heads[@a] = @two
        @tree.heads[@b] = @one
      end

      it "should advance the head to that node" do
        @tree.add(@b, ['two', '2'])
        @tree.heads[@b].should equal(@two)
      end

      it "should add the style to the new head node" do
        @tree.add(@b, ['two', '2'])
        @tree.heads[@b].should equal(@two)
      end
    end

    describe "when there is no node under the head for the given arguments" do
      before do
        #
        #  root --- one
        #            ^
        #           a,b
        #
        @tree = Tree.new(StyleSet[@a])
        one = Node.new([@a, @b], ['one', '1'])
        @tree.root.children << one
        @tree.heads[@a] = one
        @tree.heads[@b] = one
      end

      it "should create a new child node and advance the head to it" do
        old_head = @tree.heads[@a]
        @tree.add(@a, ['two', '2'])
        @tree.heads[@a].should == old_head.children.first
      end

      it "should set the arguments of the new node to the given arguments" do
        @tree.add(@a, ['two', '2'])
        @tree.heads[@a].arguments.should == ['two', '2']
      end

      it "should add the style to the new head node" do
        @tree.add(@a, ['two', '2'])
        @tree.heads[@a].styles.should == [@a]
      end
    end
  end

  describe "#arguments" do
    describe "for a nonbranching tree" do
      it "should return just the output file if there are no operations to perform" do
        tree = Tree.new(StyleSet[@a])
        tree.output(@a, 'A.jpg')
        tree.arguments.should == ['A.jpg']
      end

      it "should return the operator arguments strung together with the output file at the end" do
        tree = Tree.new(StyleSet[@a])
        tree.add(@a, ['-flip'])
        tree.add(@a, ['-flop'])
        tree.output(@a, 'A.jpg')
        tree.arguments.should == ['-flip', '-flop', 'A.jpg']
      end

      it "should use a -write argument for all but the last output file" do
        tree = Tree.new(StyleSet[@a, @b])
        tree.add(@a, ['-flip'])
        tree.add(@b, ['-flip'])
        tree.output(@a, 'A.jpg')
        tree.output(@b, 'B.jpg')
        tree.arguments.should == ['-flip', '-write', 'A.jpg', 'B.jpg']
      end
    end

    describe "for a branching tree" do
      it "should clone all but the last level" do
        tree = Tree.new(StyleSet[@a, @b])
        tree.add(@a, ['-auto-orient'])
        tree.add(@b, ['-auto-orient'])
        tree.add(@a, ['-flip'])
        tree.add(@b, ['-flop'])
        tree.output(@a, 'A.jpg')
        tree.output(@b, 'B.jpg')
        tree.arguments.should == ['-auto-orient', '(', '+clone', '-flip', '-write', 'A.jpg', '+delete', ')', '-flop', 'B.jpg']
      end
    end
  end

  describe "#each_callback" do
    it "should yield callbacks, along with the styles they apply to, in the order they appear in the tree" do
      #
      # * one (1)
      #   * two (2)     [:a]
      #   * three
      #     * four (4)  [:b]
      #
      tokens = []
      tree = Tree.new(StyleSet[@a, @b])
      tree.add(@a, ['one']){tokens << 1}
      tree.add(@a, ['two']){tokens << 2}

      tree.add(@b, ['one']){tokens << 1}
      tree.add(@b, ['three']){tokens << 2}
      tree.add(@b, ['four']){tokens << 4}
    end
  end
end
