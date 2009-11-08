require 'spec_helper'

describe Processor::Ffmpeg do
  before do
    stub_system_calls
    @styles = StyleSet.new
    @record = mock
    @attachment = mock
    @attachment.stubs(:path).returns('OUTPUT.avi')
    @attachment.stubs(:record).returns(@record)
  end

  use_temporary_attribute_value Processor::Ffmpeg, :ffmpeg_command, 'FFMPEG'

  def style(name, attributes={})
    @styles << Style.new(name, attributes)
  end

  def process(&block)
    Processor::Ffmpeg.new(@attachment, @styles, 'INPUT.avi').process(&block)
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

  describe "#record_frame" do
    before do
      @attachment.stubs(:duration).returns(20)
    end

    describe "when no attachment to assign to is given" do
      it "should force a frame record" do
        style :frame, :format => 'png'
        Kernel.expects(:system).once.with('FFMPEG', '-i', 'INPUT.avi', '-vframes', '1', '-ss', '10', '-f', 'image2', '-vcodec', 'png', '-y', 'OUTPUT.avi')
        process{record_frame}
      end

      it "should allow overriding style attributes from parameters" do
        style :frame, :position => 5
        Kernel.expects(:system).once.with('FFMPEG', '-i', 'INPUT.avi', '-vframes', '1', '-ss', '15', '-f', 'image2', '-vcodec', 'mjpeg', '-y', 'OUTPUT.avi')
        process{record_frame(:position => 15, :codec => 'mjpeg')}
      end

      it "should yield the path to the block if one is given" do
        frame_path = "#{temporary_directory}/frame.jpg"
        @attachment.stubs(:path).returns(frame_path)
        Kernel.expects(:system).once.returns(true)
        spec = self
        block_run = false
        style :frame, :format => 'jpg', :path => frame_path
        process do
          record_frame do |path|
            block_run = true
            spec.instance_eval do
              path.should == frame_path
            end
          end
        end
        block_run.should be_true
      end
    end

    describe "when an attachment to assign to is given" do
      before do
        class << @record
          attr_accessor :frame
        end
        @record.frame = mock
        @record.frame.stubs(:interpolate_path).with(:original).returns(frame_path)
      end

      def frame_path
        "#{temporary_directory}/frame.jpg"
      end

      it "should output the file to the specified attachment's original path" do
        style :original
        Kernel.expects(:system).with('FFMPEG', '-i', 'INPUT.avi', '-vframes', '1', '-ss', '10', '-f', 'image2', '-vcodec', 'mjpeg', '-y', frame_path)
        process do
          record_frame(:format => 'jpg', :assign_to => :frame)
        end
      end

      it "should assign the file to the specified attachment" do
        style :original
        process do
          record_frame(:format => 'jpg', :assign_to => :frame)
        end
        @record.frame.should be_a(SavedFile)
        @record.frame.path.should == frame_path
      end

      it "should still yield the path to any block passed, in the context of the processor" do
        context = nil
        argument = nil
        style :original
        process do
          record_frame(:format => 'jpg', :assign_to => :frame) do |path|
            context = self
            argument = path
          end
        end
        context.should be_a(Processor::Ffmpeg)
        argument.should == frame_path
      end
    end
  end

  describe "frame recording style attributes" do
    before do
      @attachment.stubs(:duration).returns(20)
    end

    it "should record a frame at the given position" do
      style :one, :format => 'png'
      Kernel.expects(:system).once.with('FFMPEG', '-i', 'INPUT.avi', '-vframes', '1', '-ss', '19', '-f', 'image2', '-vcodec', 'png', '-y', 'OUTPUT.avi')
      process{record_frame(:position => 19)}
    end

    it "should default to recording a frame at the halfway point" do
      style :one, :format => 'png'
      Kernel.expects(:system).once.with('FFMPEG', '-i', 'INPUT.avi', '-vframes', '1', '-ss', '10', '-f', 'image2', '-vcodec', 'png', '-y', 'OUTPUT.avi')
      process{record_frame}
    end

    it "should record a frame at the halfway point if the given position is out of bounds" do
      style :one, :format => 'png'
      Kernel.expects(:system).once.with('FFMPEG', '-i', 'INPUT.avi', '-vframes', '1', '-ss', '21', '-f', 'image2', '-vcodec', 'png', '-y', 'OUTPUT.avi')
      process{record_frame(:position => 21)}
    end

    it "should use the specified codec if given" do
      style :one, :format => 'png'
      Kernel.expects(:system).once.with('FFMPEG', '-i', 'INPUT.avi', '-vframes', '1', '-ss', '10', '-f', 'image2', '-vcodec', 'mjpeg', '-y', 'OUTPUT.avi')
      process{record_frame(:codec => 'mjpeg')}
    end

    it "should use the mjpeg codec by default for jpg images" do
      style :one, :format => 'jpg'
      Kernel.expects(:system).once.with('FFMPEG', '-i', 'INPUT.avi', '-vframes', '1', '-ss', '10', '-f', 'image2', '-vcodec', 'mjpeg', '-y', 'OUTPUT.avi')
      process{record_frame}
    end

    it "should use the mjpeg codec by default for jpeg images" do
      style :one, :format => 'jpeg'
      Kernel.expects(:system).once.with('FFMPEG', '-i', 'INPUT.avi', '-vframes', '1', '-ss', '10', '-f', 'image2', '-vcodec', 'mjpeg', '-y', 'OUTPUT.avi')
      process{record_frame}
    end

    it "should use the png codec by default for png images" do
      style :one, :format => 'png'
      Kernel.expects(:system).once.with('FFMPEG', '-i', 'INPUT.avi', '-vframes', '1', '-ss', '10', '-f', 'image2', '-vcodec', 'png', '-y', 'OUTPUT.avi')
      process{record_frame}
    end
  end

  describe "encoding style attributes" do
    describe "video" do
      it "should interpret '30fps' as a frame rate of 30fps" do
        style :one, :video => '30fps'
        Kernel.expects(:system).once.with('FFMPEG', '-i', 'INPUT.avi', '-r', '30', '-y', 'OUTPUT.avi')
        process{encode}
      end

      it "should interpret '30FPS' as a frame rate of 30fps" do
        style :one, :video => '30FPS'
        Kernel.expects(:system).once.with('FFMPEG', '-i', 'INPUT.avi', '-r', '30', '-y', 'OUTPUT.avi')
        process{encode}
      end

      it "should interpret 628kbps as a video bit rate of 628kbps" do
        style :one, :video => '628kbps'
        Kernel.expects(:system).once.with('FFMPEG', '-i', 'INPUT.avi', '-b', '628k', '-y', 'OUTPUT.avi')
        process{encode}
      end

      it "should interpret 400x300 as the video size" do
        style :one, :video => '400x300'
        Kernel.expects(:system).once.with('FFMPEG', '-i', 'INPUT.avi', '-s', '400x300', '-y', 'OUTPUT.avi')
        process{encode}
      end

      it "should interpret 400X300 as the video size" do
        style :one, :video => '400X300'
        Kernel.expects(:system).once.with('FFMPEG', '-i', 'INPUT.avi', '-s', '400x300', '-y', 'OUTPUT.avi')
        process{encode}
      end

      it "should interpret any other word as a video codec" do
        style :one, :video => 'libx264'
        Kernel.expects(:system).once.with('FFMPEG', '-i', 'INPUT.avi', '-vcodec', 'libx264', '-y', 'OUTPUT.avi')
        process{encode}
      end

      it "should combine multiple attributes of the video stream as given" do
        style :one, :video => 'libx264 30fps 628kbps'
        Kernel.expects(:system).once.with('FFMPEG', '-i', 'INPUT.avi', '-vcodec', 'libx264', '-r', '30', '-b', '628k', '-y', 'OUTPUT.avi')
        process{encode}
      end
    end

    describe "audio" do
      it "should interpret '44100Hz' as a sampling frequency of 44100Hz" do
        style :one, :audio => '44100Hz'
        Kernel.expects(:system).once.with('FFMPEG', '-i', 'INPUT.avi', '-ar', '44100', '-y', 'OUTPUT.avi')
        process{encode}
      end

      it "should interpret '44100hz' as a sampling frequency of 44100Hz" do
        style :one, :audio => '44100hz'
        Kernel.expects(:system).once.with('FFMPEG', '-i', 'INPUT.avi', '-ar', '44100', '-y', 'OUTPUT.avi')
        process{encode}
      end

      it "should interpret '64kbps' as a sampling frequency of 64kbps" do
        style :one, :audio => '64kbps'
        Kernel.expects(:system).once.with('FFMPEG', '-i', 'INPUT.avi', '-ab', '64k', '-y', 'OUTPUT.avi')
        process{encode}
      end

      it "should interpret 'mono' as 1 channel" do
        style :one, :audio => 'mono'
        Kernel.expects(:system).once.with('FFMPEG', '-i', 'INPUT.avi', '-ac', '1', '-y', 'OUTPUT.avi')
        process{encode}
      end

      it "should interpret 'stereo' as 2 channels" do
        style :one, :audio => 'stereo'
        Kernel.expects(:system).once.with('FFMPEG', '-i', 'INPUT.avi', '-ac', '2', '-y', 'OUTPUT.avi')
        process{encode}
      end

      it "should interpret any other word as an audio codec" do
        style :one, :audio => 'libfaac'
        Kernel.expects(:system).once.with('FFMPEG', '-i', 'INPUT.avi', '-acodec', 'libfaac', '-y', 'OUTPUT.avi')
        process{encode}
      end

      it "should combine multiple attributes of the audio stream as given" do
        style :one, :audio => 'libfaac 44100Hz 64kbps'
        Kernel.expects(:system).once.with('FFMPEG', '-i', 'INPUT.avi', '-acodec', 'libfaac', '-ar', '44100', '-ab', '64k', '-y', 'OUTPUT.avi')
        process{encode}
      end
    end

    describe "size" do
      it "should set the video size" do
        style :one, :size => '400x300'
        Kernel.expects(:system).once.with('FFMPEG', '-i', 'INPUT.avi', '-s', '400x300', '-y', 'OUTPUT.avi')
        process{encode}
      end
    end

    describe "num_channels" do
      it "should set the number of channels" do
        style :one, :num_channels => 2
        Kernel.expects(:system).once.with('FFMPEG', '-i', 'INPUT.avi', '-ac', '2', '-y', 'OUTPUT.avi')
        process{encode}
      end
    end

    describe "deinterlaced" do
      it "should set the deinterlace flag" do
        style :one, :deinterlaced => true
        Kernel.expects(:system).once.with('FFMPEG', '-i', 'INPUT.avi', '-deinterlace', '-y', 'OUTPUT.avi')
        process{encode}
      end
    end

    describe "pixel_format" do
      it "should set the pixel format" do
        style :one, :pixel_format => 'yuv420p'
        Kernel.expects(:system).once.with('FFMPEG', '-i', 'INPUT.avi', '-pix_fmt', 'yuv420p', '-y', 'OUTPUT.avi')
        process{encode}
      end
    end

    describe "b_strategy" do
      it "should set the b-strategy" do
        style :one, :b_strategy => 1
        Kernel.expects(:system).once.with('FFMPEG', '-i', 'INPUT.avi', '-b_strategy', '1', '-y', 'OUTPUT.avi')
        process{encode}
      end
    end

    describe "buffer_size" do
      it "should set the video buffer verifier buffer size" do
        style :one, :buffer_size => '2M'
        Kernel.expects(:system).once.with('FFMPEG', '-i', 'INPUT.avi', '-bufsize', '2M', '-y', 'OUTPUT.avi')
        process{encode}
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
