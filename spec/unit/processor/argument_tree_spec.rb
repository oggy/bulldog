require 'spec_helper'

describe Processor::ArgumentTree do
  Tree = Processor::ArgumentTree

  before do
    @a = Style.new(:a)
    @b = Style.new(:b)
    @c = Style.new(:c)
    @d = Style.new(:d)
  end

  describe "initially" do
    before do
      @tree = Tree.new([@a, @b])
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
    before do
      @tree = Tree.new([@a, @b, @c, @d])
    end

    describe "when the operations apply to all of the styles of a head node" do
      before do
        @tree.add(@a => ['a', 'b'], @b => ['a', 'b'], @c => ['a', 'b'], @d => ['a', 'b'])
      end

      it "should add the given arguments for the given styles to the affected head node" do
        @tree.root.children.should be_empty
        @tree.root.arguments.should == ['a', 'b']
      end
    end

    describe "when the operations apply to a proper subset of the styles of a head node" do
      before do
        @tree.add(@b => ['a', 'b'], @c => ['a', 'b'])
      end

      it "should split the head in two" do
        @tree.root.children.should have(2).nodes
        first, second = *@tree.root.children
        @tree.heads[@a].should == second
        @tree.heads[@b].should == first
        @tree.heads[@c].should == first
        @tree.heads[@d].should == second
      end

      it "should add the operations only to the affected head" do
        first, second = *@tree.root.children
        @tree.heads[@b].arguments.should == ['a', 'b']
      end

      describe "when operations are now added for all of the styles in one of the heads" do
        before do
          @tree.add(@a => 'c', @d => 'c')
        end

        it "should not move any heads" do
          first, second = *@tree.root.children
          @tree.heads[@a].should == second
          @tree.heads[@b].should == first
          @tree.heads[@c].should == first
          @tree.heads[@d].should == second
        end

        it "should add the operations to the affected head" do
          first, second = *@tree.root.children
          first.arguments.should == ['a', 'b']
          second.arguments.should == ['c']
        end
      end
    end

    describe "when the operations apply to some of styles of two head nodes" do
      before do
        @first = Tree::Node.new([@a, @b], ['a'])
        @second = Tree::Node.new([@c], ['b'])
        @tree.root.add_child(@first)
        @tree.root.add_child(@second)
        @tree.heads[@a] = @first
        @tree.heads[@b] = @first
        @tree.heads[@c] = @second

        @tree.add(@b => 'c')
      end

      it "should split heads in two where necessary" do
        @tree.root.children.should == [@first, @second]
        @first.styles.should == [@a, @b]
        @first.children.should have(2).node

        child1, child2 = *@first.children
        child1.styles.should == [@b]
        child2.styles.should == [@a]
      end

      it "should add the operations only to the affected heads" do
        child1, child2 = *@first.children
        child1.arguments.should == ['c']
        child2.arguments.should == []
      end
    end
  end

  describe "#remove_style" do
    describe "when the head has other styles in it" do
      before do
        @tree = Tree.new([@a, @b, @c])
        @tree.root.add_child(Tree::Node.new([@a, @b, @c]))
        @tree.add(@a => 'a')
      end

      it "should remove the style from the head" do
        @tree.root.children.last.styles.should == [@b, @c]
        @tree.remove_style(@b)
        @tree.root.children.last.styles.should == [@c]
      end

      it "should no longer have a head for the style" do
        @tree.remove_style(@b)
        @tree.heads[@b].should be_nil
      end
    end

    describe "when the style is the only style in its head" do
      before do
        @tree = Tree.new([@a, @b])
        @tree.add(@a => 'a')
      end

      it "should remove the node entirely" do
        @tree.root.children.map(&:styles) == [[@a], [@b]]
        @tree.remove_style(@b)
        @tree.root.children.map(&:styles) == [[@a]]
      end

      it "should no longer have a head for the style" do
        @tree.remove_style(@b)
        @tree.heads[@b].should be_nil
      end
    end

    describe "when the style is the only style in its head and the head is the root node" do
      before do
        @tree = Tree.new([@a])
      end

      it "should not remove the root node" do
        @tree.remove_style(@a)
        @tree.root.should_not be_nil
        @tree.root.styles.should be_empty
      end
    end
  end
end
