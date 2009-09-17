require 'spec_helper'

describe Processor::Convert do
  before do
    stub_system_calls

    @original_command = Processor::Convert.command
    Processor::Convert.command = 'CONVERT'

    @styles = StyleSet.new
  end

  after do
    Processor::Convert.command = @original_command
  end

  include Processor

  def style(name, attributes)
    @styles << Style.new(name, attributes)
  end

  def process(&block)
    Processor::Convert.new('INPUT.jpg', @styles).process(nil, nil, &block)
  end

  describe "when a simple conversion is performed" do
    before do
      style :x, {:path => '/tmp/x.jpg'}
    end

    it "should run convert with the required arguments" do
      Kernel.expects(:system).once.with('CONVERT', 'INPUT.jpg', '/tmp/x.jpg')
      process
    end

    it "should log the command run" do
      Bulldog.logger.expects(:info).with('Running: "CONVERT" "INPUT.jpg" "/tmp/x.jpg"')
      process
    end
  end

  it "should not blow up if the logger is set to nil" do
    Bulldog.logger = nil
    style :x, {:path => '/tmp/x.jpg'}
    lambda{process{}}.should_not raise_error
  end

  it "should run a simple pipeline if there is 1 output file" do
    Kernel.expects(:system).once.with(
      'CONVERT', 'INPUT.jpg', '-auto-orient', '-resize', '40x40', '/tmp/small.jpg'
    )
    style :small, {:size => '40x40', :path => '/tmp/small.jpg'}
    process do
      auto_orient
      resize
    end
  end

  describe "#thumbnail" do
    it "should resize, and crop off the edges" do
      style :small, {:size => '10x10', :path => '/tmp/small.jpg'}
      Kernel.expects(:system).once.with(
        'CONVERT', 'INPUT.jpg',
        '-resize', '10x10^',
        '-gravity', 'Center',
        '-crop', '10x10',
        '/tmp/small.jpg'
      )
      process do
        thumbnail
      end
    end
  end

  it "should extract a common prefix if there are multiple styles which start with the same operations" do
    Kernel.expects(:system).once.with(
      'CONVERT', 'INPUT.jpg', '-auto-orient',
      '(', '+clone', '-resize', '100x100', '-write', '/tmp/big.jpg', '+delete', ')',
      '-resize', '40x40', '/tmp/small.jpg'
    )
    style :big, {:size => '100x100', :path => '/tmp/big.jpg'}
    style :small, {:size => '40x40', :path => '/tmp/small.jpg'}
    process do
      auto_orient
      resize
    end
  end

  it "should allow specifying operations only for some styles with an :only option" do
    Kernel.expects(:system).once.with(
      'CONVERT', 'INPUT.jpg',
      '(', '+clone', '-auto-orient', '-write', '/tmp/auto_oriented.jpg', '+delete', ')',
      '(', '+clone', '-resize', '40x40', '-write', '/tmp/small.jpg', '+delete', ')',
      '-resize', '100x100', '/tmp/big.jpg'
    )
    style :auto_oriented, {:path => '/tmp/auto_oriented.jpg'}
    style :small, {:size => '40x40', :path => '/tmp/small.jpg'}
    style :big, {:size => '100x100', :path => '/tmp/big.jpg'}
    process do
      auto_orient(:only => :auto_oriented)
      resize(:only => [:small, :big])
    end
  end

  it "should allow protecting styles from an operation with an :except option" do
    Kernel.expects(:system).once.with(
      'CONVERT', 'INPUT.jpg',
      '(', '+clone', '-write', '/tmp/unaltered.jpg', '+delete', ')',
      '(', '+clone', '-auto-orient', '-write', '/tmp/unresized.jpg', '+delete', ')',
      '-auto-orient', '-resize', '40x40', '/tmp/small.jpg'
    )
    style :unaltered, {:path => '/tmp/unaltered.jpg'}
    style :unresized, {:path => '/tmp/unresized.jpg'}
    style :small, {:size => '40x40', :path => '/tmp/small.jpg'}
    process do
      auto_orient(:except => :unaltered)
      resize(:except => [:unaltered, :unresized])
    end
  end
end