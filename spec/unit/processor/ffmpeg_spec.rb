require 'spec_helper'

describe Processor::Ffmpeg do
  before do
    stub_system_calls
    @styles = StyleSet.new
  end

  use_temporary_attribute_value Processor::Ffmpeg, :ffmpeg_command, 'FFMPEG'

  def style(name, attributes={})
    @styles << Style.new(name, attributes)
  end

  def fake_attachment
    attachment = Object.new
    styles = @styles
    (class << attachment; self; end).class_eval do
      define_method(:path){|style_name| 'OUTPUT.avi'}
    end
    attachment
  end

  def process(&block)
    Processor::Ffmpeg.new(fake_attachment, @styles, 'INPUT.avi').process(&block)
  end

  describe "when a simple conversion is performed" do
    before do
      style :one
    end

    it "should run ffmpeg" do
      Kernel.expects(:system).once.with('FFMPEG', '-i', 'INPUT.avi', '-y', 'OUTPUT.avi')
      process
    end

    it "should log the command run" do
      Bulldog.logger.expects(:info).with('Running: "FFMPEG" "-i" "INPUT.avi" "-y" "OUTPUT.avi"')
      process
    end
  end

  describe "#encode" do
    it "should force an encode" do
      style :one
      Kernel.expects(:system).once.with('FFMPEG', '-i', 'INPUT.avi', '-y', 'OUTPUT.avi')
      process{encode}
    end

    it "should allow overriding style attributes from parameters" do
      style :one, :size => '400x300'
      Kernel.expects(:system).once.with('FFMPEG', '-i', 'INPUT.avi', '-s', '600x450', '-y', 'OUTPUT.avi')
      process{encode(:size => '600x450')}
    end
  end

  describe "style attributes" do
    describe "video" do
      it "should interpret '30fps' as a frame rate of 30fps" do
        style :one, :video => '30fps'
        Kernel.expects(:system).once.with('FFMPEG', '-i', 'INPUT.avi', '-r', '30', '-y', 'OUTPUT.avi')
        process
      end

      it "should interpret '30FPS' as a frame rate of 30fps" do
        style :one, :video => '30FPS'
        Kernel.expects(:system).once.with('FFMPEG', '-i', 'INPUT.avi', '-r', '30', '-y', 'OUTPUT.avi')
        process
      end

      it "should interpret 628kbps as a video bit rate of 628kbps" do
        style :one, :video => '628kbps'
        Kernel.expects(:system).once.with('FFMPEG', '-i', 'INPUT.avi', '-b', '628k', '-y', 'OUTPUT.avi')
        process
      end

      it "should interpret 400x300 as the video size" do
        style :one, :video => '400x300'
        Kernel.expects(:system).once.with('FFMPEG', '-i', 'INPUT.avi', '-s', '400x300', '-y', 'OUTPUT.avi')
        process
      end

      it "should interpret 400X300 as the video size" do
        style :one, :video => '400X300'
        Kernel.expects(:system).once.with('FFMPEG', '-i', 'INPUT.avi', '-s', '400x300', '-y', 'OUTPUT.avi')
        process
      end

      it "should interpret any other word as a video codec" do
        style :one, :video => 'libx264'
        Kernel.expects(:system).once.with('FFMPEG', '-i', 'INPUT.avi', '-vcodec', 'libx264', '-y', 'OUTPUT.avi')
        process
      end

      it "should combine multiple attributes of the video stream as given" do
        style :one, :video => 'libx264 30fps 628kbps'
        Kernel.expects(:system).once.with('FFMPEG', '-i', 'INPUT.avi', '-vcodec', 'libx264', '-r', '30', '-b', '628k', '-y', 'OUTPUT.avi')
        process
      end
    end

    describe "audio" do
      it "should interpret '44100Hz' as a sampling frequency of 44100Hz" do
        style :one, :audio => '44100Hz'
        Kernel.expects(:system).once.with('FFMPEG', '-i', 'INPUT.avi', '-ar', '44100', '-y', 'OUTPUT.avi')
        process
      end

      it "should interpret '44100hz' as a sampling frequency of 44100Hz" do
        style :one, :audio => '44100hz'
        Kernel.expects(:system).once.with('FFMPEG', '-i', 'INPUT.avi', '-ar', '44100', '-y', 'OUTPUT.avi')
        process
      end

      it "should interpret '64kbps' as a sampling frequency of 64kbps" do
        style :one, :audio => '64kbps'
        Kernel.expects(:system).once.with('FFMPEG', '-i', 'INPUT.avi', '-ab', '64k', '-y', 'OUTPUT.avi')
        process
      end

      it "should interpret 'mono' as 1 channel" do
        style :one, :audio => 'mono'
        Kernel.expects(:system).once.with('FFMPEG', '-i', 'INPUT.avi', '-ac', '1', '-y', 'OUTPUT.avi')
        process
      end

      it "should interpret 'stereo' as 2 channels" do
        style :one, :audio => 'stereo'
        Kernel.expects(:system).once.with('FFMPEG', '-i', 'INPUT.avi', '-ac', '2', '-y', 'OUTPUT.avi')
        process
      end

      it "should interpret any other word as an audio codec" do
        style :one, :audio => 'libfaac'
        Kernel.expects(:system).once.with('FFMPEG', '-i', 'INPUT.avi', '-acodec', 'libfaac', '-y', 'OUTPUT.avi')
        process
      end

      it "should combine multiple attributes of the audio stream as given" do
        style :one, :audio => 'libfaac 44100Hz 64kbps'
        Kernel.expects(:system).once.with('FFMPEG', '-i', 'INPUT.avi', '-acodec', 'libfaac', '-ar', '44100', '-ab', '64k', '-y', 'OUTPUT.avi')
        process
      end
    end

    describe "size" do
      it "should set the video size" do
        style :one, :size => '400x300'
        Kernel.expects(:system).once.with('FFMPEG', '-i', 'INPUT.avi', '-s', '400x300', '-y', 'OUTPUT.avi')
        process
      end
    end

    describe "num_channels" do
      it "should set the number of channels" do
        style :one, :num_channels => 2
        Kernel.expects(:system).once.with('FFMPEG', '-i', 'INPUT.avi', '-ac', '2', '-y', 'OUTPUT.avi')
        process
      end
    end

    describe "deinterlaced" do
      it "should set the deinterlace flag" do
        style :one, :deinterlaced => true
        Kernel.expects(:system).once.with('FFMPEG', '-i', 'INPUT.avi', '-deinterlace', '-y', 'OUTPUT.avi')
        process
      end
    end

    describe "pixel_format" do
      it "should set the pixel format" do
        style :one, :pixel_format => 'yuv420p'
        Kernel.expects(:system).once.with('FFMPEG', '-i', 'INPUT.avi', '-pix_fmt', 'yuv420p', '-y', 'OUTPUT.avi')
        process
      end
    end

    describe "b_strategy" do
      it "should set the b-strategy" do
        style :one, :b_strategy => 1
        Kernel.expects(:system).once.with('FFMPEG', '-i', 'INPUT.avi', '-b_strategy', '1', '-y', 'OUTPUT.avi')
        process
      end
    end

    describe "buffer_size" do
      it "should set the video buffer verifier buffer size" do
        style :one, :buffer_size => '2M'
        Kernel.expects(:system).once.with('FFMPEG', '-i', 'INPUT.avi', '-bufsize', '2M', '-y', 'OUTPUT.avi')
        process
      end
    end
  end

  describe "#use_threads" do
    it "should set the number of threads" do
      style :one
      Kernel.expects(:system).once.with('FFMPEG', '-i', 'INPUT.avi', '-threads', '2', '-y', 'OUTPUT.avi')
      process{use_threads 2}
    end
  end
end
