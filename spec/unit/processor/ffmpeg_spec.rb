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
      Bulldog.expects(:run).once.with('FFMPEG', '-i', 'INPUT.avi', '-y', 'OUTPUT.avi')
      process
    end

    it "should log the command run" do
      log_path = "#{temporary_directory}/log"
      open(log_path, 'w') do |file|
        Bulldog.logger = Logger.new(file)
        process
      end
      File.read(log_path).should include("[Bulldog] Running: FFMPEG")
    end
  end

  describe "#encode" do
    it "should force an encode" do
      style :one
      Bulldog.expects(:run).once.with('FFMPEG', '-i', 'INPUT.avi', '-y', 'OUTPUT.avi')
      process{encode}
    end

    it "should allow overriding style attributes from parameters" do
      style :one, :size => '400x300'
      Bulldog.expects(:run).once.with('FFMPEG', '-i', 'INPUT.avi', '-s', '600x450', '-y', 'OUTPUT.avi')
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
        Bulldog.expects(:run).once.with('FFMPEG', '-i', 'INPUT.avi', '-vframes', '1', '-ss', '10', '-f', 'image2', '-vcodec', 'png', '-y', 'OUTPUT.avi')
        process{record_frame}
      end

      it "should allow overriding style attributes from parameters" do
        style :frame, :position => 5
        Bulldog.expects(:run).once.with('FFMPEG', '-i', 'INPUT.avi', '-vframes', '1', '-ss', '15', '-f', 'image2', '-vcodec', 'mjpeg', '-y', 'OUTPUT.avi')
        process{record_frame(:position => 15, :codec => 'mjpeg')}
      end

      it "should yield the path to the block if one is given" do
        frame_path = "#{temporary_directory}/frame.jpg"
        @attachment.stubs(:path).returns(frame_path)
        Bulldog.expects(:run).once.returns(true)
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
      set_up_model_class :Thing do |t|
        t.string :video_file_name
        t.string :frame_file_name
      end

      before do
        spec = self
        Thing.class_eval do
          has_attachment :video do
            path "#{spec.temporary_directory}/video.:style.:extension"
          end

          has_attachment :frame do
            path "#{spec.temporary_directory}/frame.:style.:extension"
          end
        end

        thing = Thing.create(:video => test_video_file('test.mov'))
        @thing = Thing.find(thing.id)
      end

      def original_video_path
        "#{temporary_directory}/video.original.mov"
      end

      def original_frame_path
        "#{temporary_directory}/frame.original.jpg"
      end

      def configure(attachment_name, &block)
        Thing.attachment_reflections[attachment_name].configure(&block)
      end

      it "should output the file to the specified attachment's original path" do
        configure :video do
          process :on => :make_frame, :styles => [:original] do
            record_frame(:format => 'jpg', :assign_to => :frame)
          end
        end
        Bulldog.expects(:run).once.with('FFMPEG', '-i', original_video_path, '-vframes', '1', '-ss', '0', '-f', 'image2', '-vcodec', 'mjpeg', '-y', original_frame_path)
        @thing.process_attachment(:video, :make_frame)
      end

      it "should assign the file to the specified attachment" do
        configure :video do
          process :on => :make_frame, :styles => [:original] do
            record_frame(:format => 'jpg', :assign_to => :frame)
          end
        end
        @thing.process_attachment(:video, :make_frame)
        @thing.frame.should_not be_blank
      end

      it "should yield the written path to any block passed, in the context of the processor" do
        context = nil
        argument = nil
        configure :video do
          process :on => :make_frame, :styles => [:original] do
            record_frame(:format => 'jpg', :assign_to => :frame) do |path|
              context = self
              argument = path
            end
          end
        end
        @thing.process_attachment(:video, :make_frame)
        context.should be_a(Processor::Ffmpeg)
        argument.should == original_frame_path
      end
    end

    describe "using style attributes" do
      it "should record a frame at the given position" do
        style :one, :format => 'png'
        Bulldog.expects(:run).once.with('FFMPEG', '-i', 'INPUT.avi', '-vframes', '1', '-ss', '19', '-f', 'image2', '-vcodec', 'png', '-y', 'OUTPUT.avi')
        process{record_frame(:position => 19)}
      end

      it "should default to recording a frame at the halfway point" do
        style :one, :format => 'png'
        Bulldog.expects(:run).once.with('FFMPEG', '-i', 'INPUT.avi', '-vframes', '1', '-ss', '10', '-f', 'image2', '-vcodec', 'png', '-y', 'OUTPUT.avi')
        process{record_frame}
      end

      it "should record a frame at the halfway point if the given position is out of bounds" do
        style :one, :format => 'png'
        Bulldog.expects(:run).once.with('FFMPEG', '-i', 'INPUT.avi', '-vframes', '1', '-ss', '21', '-f', 'image2', '-vcodec', 'png', '-y', 'OUTPUT.avi')
        process{record_frame(:position => 21)}
      end

      it "should use the specified codec if given" do
        style :one, :format => 'png'
        Bulldog.expects(:run).once.with('FFMPEG', '-i', 'INPUT.avi', '-vframes', '1', '-ss', '10', '-f', 'image2', '-vcodec', 'mjpeg', '-y', 'OUTPUT.avi')
        process{record_frame(:codec => 'mjpeg')}
      end

      it "should use the mjpeg codec by default for jpg images" do
        style :one, :format => 'jpg'
        Bulldog.expects(:run).once.with('FFMPEG', '-i', 'INPUT.avi', '-vframes', '1', '-ss', '10', '-f', 'image2', '-vcodec', 'mjpeg', '-y', 'OUTPUT.avi')
        process{record_frame}
      end

      it "should use the mjpeg codec by default for jpeg images" do
        style :one, :format => 'jpeg'
        Bulldog.expects(:run).once.with('FFMPEG', '-i', 'INPUT.avi', '-vframes', '1', '-ss', '10', '-f', 'image2', '-vcodec', 'mjpeg', '-y', 'OUTPUT.avi')
        process{record_frame}
      end

      it "should use the png codec by default for png images" do
        style :one, :format => 'png'
        Bulldog.expects(:run).once.with('FFMPEG', '-i', 'INPUT.avi', '-vframes', '1', '-ss', '10', '-f', 'image2', '-vcodec', 'png', '-y', 'OUTPUT.avi')
        process{record_frame}
      end
    end
  end

  describe "encoding style attributes" do
    describe "video" do
      it "should interpret '30fps' as a frame rate of 30fps" do
        style :one, :video => '30fps'
        Bulldog.expects(:run).once.with('FFMPEG', '-i', 'INPUT.avi', '-r', '30', '-y', 'OUTPUT.avi')
        process{encode}
      end

      it "should interpret '30FPS' as a frame rate of 30fps" do
        style :one, :video => '30FPS'
        Bulldog.expects(:run).once.with('FFMPEG', '-i', 'INPUT.avi', '-r', '30', '-y', 'OUTPUT.avi')
        process{encode}
      end

      it "should interpret 628kbps as a video bit rate of 628kbps" do
        style :one, :video => '628kbps'
        Bulldog.expects(:run).once.with('FFMPEG', '-i', 'INPUT.avi', '-b', '628k', '-y', 'OUTPUT.avi')
        process{encode}
      end

      it "should interpret any other word as a video codec" do
        style :one, :video => 'libx264'
        Bulldog.expects(:run).once.with('FFMPEG', '-i', 'INPUT.avi', '-vcodec', 'libx264', '-y', 'OUTPUT.avi')
        process{encode}
      end

      it "should combine multiple attributes of the video stream as given" do
        style :one, :video => 'libx264 30fps 628kbps'
        Bulldog.expects(:run).once.with('FFMPEG', '-i', 'INPUT.avi', '-vcodec', 'libx264', '-r', '30', '-b', '628k', '-y', 'OUTPUT.avi')
        process{encode}
      end
    end

    describe "audio" do
      it "should interpret '44100Hz' as a sampling frequency of 44100Hz" do
        style :one, :audio => '44100Hz'
        Bulldog.expects(:run).once.with('FFMPEG', '-i', 'INPUT.avi', '-ar', '44100', '-y', 'OUTPUT.avi')
        process{encode}
      end

      it "should interpret '44100hz' as a sampling frequency of 44100Hz" do
        style :one, :audio => '44100hz'
        Bulldog.expects(:run).once.with('FFMPEG', '-i', 'INPUT.avi', '-ar', '44100', '-y', 'OUTPUT.avi')
        process{encode}
      end

      it "should interpret '64kbps' as a sampling frequency of 64kbps" do
        style :one, :audio => '64kbps'
        Bulldog.expects(:run).once.with('FFMPEG', '-i', 'INPUT.avi', '-ab', '64k', '-y', 'OUTPUT.avi')
        process{encode}
      end

      it "should interpret 'mono' as 1 channel" do
        style :one, :audio => 'mono'
        Bulldog.expects(:run).once.with('FFMPEG', '-i', 'INPUT.avi', '-ac', '1', '-y', 'OUTPUT.avi')
        process{encode}
      end

      it "should interpret 'stereo' as 2 channels" do
        style :one, :audio => 'stereo'
        Bulldog.expects(:run).once.with('FFMPEG', '-i', 'INPUT.avi', '-ac', '2', '-y', 'OUTPUT.avi')
        process{encode}
      end

      it "should interpret any other word as an audio codec" do
        style :one, :audio => 'libfaac'
        Bulldog.expects(:run).once.with('FFMPEG', '-i', 'INPUT.avi', '-acodec', 'libfaac', '-y', 'OUTPUT.avi')
        process{encode}
      end

      it "should combine multiple attributes of the audio stream as given" do
        style :one, :audio => 'libfaac 44100Hz 64kbps'
        Bulldog.expects(:run).once.with('FFMPEG', '-i', 'INPUT.avi', '-acodec', 'libfaac', '-ar', '44100', '-ab', '64k', '-y', 'OUTPUT.avi')
        process{encode}
      end
    end

    describe "video_codec" do
      it "should set the video codec" do
        style :one, :video_codec => 'libx264'
        Bulldog.expects(:run).once.with('FFMPEG', '-i', 'INPUT.avi', '-vcodec', 'libx264', '-y', 'OUTPUT.avi')
        process{encode}
      end
    end

    describe "frame_rate" do
      it "should set the frame rate" do
        style :one, :frame_rate => 30
        Bulldog.expects(:run).once.with('FFMPEG', '-i', 'INPUT.avi', '-r', '30', '-y', 'OUTPUT.avi')
        process{encode}
      end
    end

    describe "video_bit_rate" do
      it "should set the video bit rate" do
        style :one, :video_bit_rate => '64k'
        Bulldog.expects(:run).once.with('FFMPEG', '-i', 'INPUT.avi', '-b', '64k', '-y', 'OUTPUT.avi')
        process{encode}
      end
    end

    describe "audio_codec" do
      it "should set the audio codec" do
        style :one, :audio_codec => 'libfaac'
        Bulldog.expects(:run).once.with('FFMPEG', '-i', 'INPUT.avi', '-acodec', 'libfaac', '-y', 'OUTPUT.avi')
        process{encode}
      end
    end

    describe "sampling_rate" do
      it "should set the sampling rate" do
        style :one, :sampling_rate => 44100
        Bulldog.expects(:run).once.with('FFMPEG', '-i', 'INPUT.avi', '-ar', '44100', '-y', 'OUTPUT.avi')
        process{encode}
      end
    end

    describe "audio_bit_rate" do
      it "should set the audio bit rate" do
        style :one, :audio_bit_rate => '64k'
        Bulldog.expects(:run).once.with('FFMPEG', '-i', 'INPUT.avi', '-ab', '64k', '-y', 'OUTPUT.avi')
        process{encode}
      end
    end

    describe "channels" do
      it "should set the number of channels" do
        style :one, :channels => 2
        Bulldog.expects(:run).once.with('FFMPEG', '-i', 'INPUT.avi', '-ac', '2', '-y', 'OUTPUT.avi')
        process{encode}
      end
    end

    describe "video_preset" do
      it "should set a video preset" do
        style :one, :video_preset => 'one'
        Bulldog.expects(:run).once.with('FFMPEG', '-i', 'INPUT.avi', '-vpre', 'one', '-y', 'OUTPUT.avi')
        process{encode}
      end

      it "should allow setting more than one video preset" do
        style :one, :video_preset => ['one', 'two']
        Bulldog.expects(:run).once.with('FFMPEG', '-i', 'INPUT.avi', '-vpre', 'one', '-vpre', 'two', '-y', 'OUTPUT.avi')
        process{encode}
      end
    end

    describe "audio_preset" do
      it "should set a audio preset" do
        style :one, :audio_preset => 'one'
        Bulldog.expects(:run).once.with('FFMPEG', '-i', 'INPUT.avi', '-apre', 'one', '-y', 'OUTPUT.avi')
        process{encode}
      end

      it "should allow setting more than one audio preset" do
        style :one, :audio_preset => ['one', 'two']
        Bulldog.expects(:run).once.with('FFMPEG', '-i', 'INPUT.avi', '-apre', 'one', '-apre', 'two', '-y', 'OUTPUT.avi')
        process{encode}
      end
    end

    describe "subtitle_preset" do
      it "should set a subtitle preset" do
        style :one, :subtitle_preset => 'one'
        Bulldog.expects(:run).once.with('FFMPEG', '-i', 'INPUT.avi', '-spre', 'one', '-y', 'OUTPUT.avi')
        process{encode}
      end

      it "should allow setting more than one subtitle preset" do
        style :one, :subtitle_preset => ['one', 'two']
        Bulldog.expects(:run).once.with('FFMPEG', '-i', 'INPUT.avi', '-spre', 'one', '-spre', 'two', '-y', 'OUTPUT.avi')
        process{encode}
      end
    end

    describe "size" do
      it "should set the video size" do
        style :one, :size => '400x300'
        Bulldog.expects(:run).once.with('FFMPEG', '-i', 'INPUT.avi', '-s', '400x300', '-y', 'OUTPUT.avi')
        process{encode}
      end

      it "should maintain the original aspect ratio" do
        style :one, :size => '400x300'
        Bulldog.expects(:run).once.with('FFMPEG', '-i', 'INPUT.avi', '-s', '400x300', '-y', 'OUTPUT.avi')
        process{encode}
      end
    end

    describe "num_channels" do
      it "should set the number of channels" do
        style :one, :channels => 2
        Bulldog.expects(:run).once.with('FFMPEG', '-i', 'INPUT.avi', '-ac', '2', '-y', 'OUTPUT.avi')
        process{encode}
      end
    end

    describe "deinterlaced" do
      it "should set the deinterlace flag" do
        style :one, :deinterlaced => true
        Bulldog.expects(:run).once.with('FFMPEG', '-i', 'INPUT.avi', '-deinterlace', '-y', 'OUTPUT.avi')
        process{encode}
      end
    end

    describe "pixel_format" do
      it "should set the pixel format" do
        style :one, :pixel_format => 'yuv420p'
        Bulldog.expects(:run).once.with('FFMPEG', '-i', 'INPUT.avi', '-pix_fmt', 'yuv420p', '-y', 'OUTPUT.avi')
        process{encode}
      end
    end

    describe "b_strategy" do
      it "should set the b-strategy" do
        style :one, :b_strategy => 1
        Bulldog.expects(:run).once.with('FFMPEG', '-i', 'INPUT.avi', '-b_strategy', '1', '-y', 'OUTPUT.avi')
        process{encode}
      end
    end

    describe "buffer_size" do
      it "should set the video buffer verifier buffer size" do
        style :one, :buffer_size => '2M'
        Bulldog.expects(:run).once.with('FFMPEG', '-i', 'INPUT.avi', '-bufsize', '2M', '-y', 'OUTPUT.avi')
        process{encode}
      end
    end

    describe "coder" do
      it "should set the coder" do
        style :one, :coder => 'ac'
        Bulldog.expects(:run).once.with('FFMPEG', '-i', 'INPUT.avi', '-coder', 'ac', '-y', 'OUTPUT.avi')
        process{encode}
      end
    end

    describe "verbosity" do
      it "should set the verbosity" do
        style :one, :verbosity => 1
        Bulldog.expects(:run).once.with('FFMPEG', '-i', 'INPUT.avi', '-v', '1', '-y', 'OUTPUT.avi')
        process{encode}
      end
    end

    describe "flags" do
      it "should set the flags" do
        style :one, :flags => '+loop'
        Bulldog.expects(:run).once.with('FFMPEG', '-i', 'INPUT.avi', '-flags', '+loop', '-y', 'OUTPUT.avi')
        process{encode}
      end
    end
  end

  describe "#use_threads" do
    it "should set the number of threads" do
      style :one
      Bulldog.expects(:run).once.with('FFMPEG', '-i', 'INPUT.avi', '-threads', '2', '-y', 'OUTPUT.avi')
      process{use_threads 2}
    end
  end
end
