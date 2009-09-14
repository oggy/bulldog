require 'spec_helper'

describe Processor::Ffmpeg do
  before do
    stub_system_calls

    @original_ffmpeg_command = Processor::Ffmpeg.ffmpeg_command
    Processor::Ffmpeg.ffmpeg_command = 'FFMPEG'

    @styles = StyleSet.new
  end

  after do
    Processor::Ffmpeg.ffmpeg_command = @original_ffmpeg_command
  end

  def style(name, attributes)
    @styles << Style.new(name, attributes)
  end

  def process(&block)
    Processor::Ffmpeg.new('INPUT.avi', @styles).process(nil, nil, &block)
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
