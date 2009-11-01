require 'spec_helper'

describe Processor::Ffmpeg do
  before do
    stub_system_calls
    @styles = StyleSet.new
  end

  use_temporary_attribute_value Processor::Ffmpeg, :ffmpeg_command, 'FFMPEG'

  def style(name, attributes)
    @styles << Style.new(name, attributes)
  end

  def fake_attachment
    attachment = Object.new
    styles = @styles
    (class << attachment; self; end).class_eval do
      define_method(:path){|style_name| styles[style_name][:path]}
    end
    attachment
  end

  def process(&block)
    Processor::Ffmpeg.new(fake_attachment, @styles, 'INPUT.avi').process(&block)
  end

  describe "when a simple conversion is performed" do
    before do
      style :x, {:path => '/tmp/x.mp4'}
    end

    it "should run ffmpeg" do
      Kernel.expects(:system).once.with('FFMPEG', '-i', 'INPUT.avi', '/tmp/x.mp4')
      process
    end

    it "should log the command run" do
      Bulldog.logger.expects(:info).with('Running: "FFMPEG" "-i" "INPUT.avi" "/tmp/x.mp4"')
      process
    end
  end
end
