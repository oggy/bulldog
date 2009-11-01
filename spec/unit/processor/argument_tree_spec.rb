require 'spec_helper'

describe Processor::ArgumentTree do
  Tree = Processor::ArgumentTree
  Node = Processor::ArgumentTree::Node

  before do
    @a = Style.new(:a)
    @b = Style.new(:b)
    @c = Style.new(:c)
    @d = Style.new(:d)
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
end
