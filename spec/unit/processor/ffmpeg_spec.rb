require 'spec_helper'

describe Processor::Ffmpeg do
  use_model_class(:Thing,
                  :video_file_name => :string,
                  :frame_file_name => :string)

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

  def ffmpeg
    Bulldog::Processor::Ffmpeg.ffmpeg_command
  end

  def original_video_path
    "#{temporary_directory}/video.original.mov"
  end

  def output_video_path
    "#{temporary_directory}/video.output.mov"
  end

  def original_frame_path
    "#{temporary_directory}/frame.original.jpg"
  end

  def configure(attachment_name, &block)
    Thing.attachment_reflections[attachment_name].configure(&block)
  end

  def video_style(name, attributes={})
    configure(:video) do
      style name, attributes
    end
  end

  def process_video(options={}, &block)
    configure(:video) do
      process(options.merge(:on => :event, :with => :ffmpeg), &block)
    end
    @thing.video.process(:event)
  end

  describe "when a simple conversion is performed" do
    before do
      video_style :output
    end

    it "should run ffmpeg" do
      Bulldog.expects(:run).once.with(ffmpeg, '-i', original_video_path, '-y', output_video_path)
      process_video
    end

    it "should log the command run" do
      log_path = "#{temporary_directory}/log"
      open(log_path, 'w') do |file|
        Bulldog.logger = Logger.new(file)
        process_video
      end
      File.read(log_path).should include("[Bulldog] Running: #{ffmpeg}")
    end
  end

  describe "#encode" do
    it "should force an encode" do
      video_style :output
      Bulldog.expects(:run).once.with(ffmpeg, '-i', original_video_path, '-y', output_video_path)
      process_video{encode}
    end

    it "should allow overriding style attributes from parameters" do
      video_style :output, :video_codec => 'libx264'
      Bulldog.expects(:run).once.with(ffmpeg, '-i', original_video_path, '-vcodec', 'libtheora', '-y', output_video_path)
      process_video{encode(:video_codec => 'libtheora')}
    end
  end

  describe "#record_frame" do
    before do
      @thing.video.stubs(:duration).returns(20)
    end

    describe "when no attachment to assign to is given" do
      it "should force a frame record" do
        video_style :frame, :format => 'png'
        Bulldog.expects(:run).once.with(ffmpeg, '-i', original_video_path, '-vframes', '1', '-ss', '10', '-f', 'image2', '-vcodec', 'png', '-y', "#{temporary_directory}/video.frame.png")
        process_video{record_frame}
      end

      it "should allow overriding style attributes from parameters" do
        video_style :frame, :format => 'png', :position => 5
        Bulldog.expects(:run).once.with(ffmpeg, '-i', original_video_path, '-vframes', '1', '-ss', '15', '-f', 'image2', '-vcodec', 'mjpeg', '-y', "#{temporary_directory}/video.frame.png")
        process_video{record_frame(:position => 15, :codec => 'mjpeg')}
      end

      it "should yield the path to the block if one is given" do
        video_style :frame, :format => 'jpg'
        spec = self
        block_run = false
        Bulldog.expects(:run).once.returns('')
        process_video do
          record_frame do |path|
            block_run = true
            spec.instance_eval do
              path.should == "#{temporary_directory}/video.frame.jpg"
            end
          end
        end
        block_run.should be_true
      end
    end

    describe "when an attachment to assign to is given" do
      it "should output the file to the specified attachment's original path" do
        Bulldog.expects(:run).once.with(ffmpeg, '-i', original_video_path, '-vframes', '1', '-ss', '10', '-f', 'image2', '-vcodec', 'mjpeg', '-y', original_frame_path)
        process_video :styles => [:original] do
          record_frame(:format => 'jpg', :assign_to => :frame)
        end
      end

      it "should assign the file to the specified attachment" do
        process_video :styles => [:original] do
          record_frame(:format => 'jpg', :assign_to => :frame)
        end
        @thing.frame.should_not be_blank
      end

      it "should yield the written path to any block passed, in the context of the processor" do
        context = nil
        argument = nil
        process_video :styles => [:original] do
          record_frame(:format => 'jpg', :assign_to => :frame) do |path|
            context = self
            argument = path
          end
        end
        context.should be_a(Processor::Ffmpeg)
        argument.should == original_frame_path
      end
    end

    describe "using style attributes" do
      def frame_path(format)
        "#{temporary_directory}/video.output.#{format}"
      end

      it "should record a frame at the given position" do
        video_style :output, :format => 'png'
        Bulldog.expects(:run).once.with(ffmpeg, '-i', original_video_path, '-vframes', '1', '-ss', '19', '-f', 'image2', '-vcodec', 'png', '-y', frame_path('png'))
        process_video{record_frame(:position => 19)}
      end

      it "should default to recording a frame at the halfway point" do
        video_style :output, :format => 'png'
        Bulldog.expects(:run).once.with(ffmpeg, '-i', original_video_path, '-vframes', '1', '-ss', '10', '-f', 'image2', '-vcodec', 'png', '-y', frame_path('png'))
        process_video{record_frame}
      end

      it "should record a frame at the halfway point if the given position is out of bounds" do
        video_style :output, :format => 'png'
        Bulldog.expects(:run).once.with(ffmpeg, '-i', original_video_path, '-vframes', '1', '-ss', '21', '-f', 'image2', '-vcodec', 'png', '-y', frame_path('png'))
        process_video{record_frame(:position => 21)}
      end

      it "should use the specified codec if given" do
        video_style :output, :format => 'png'
        Bulldog.expects(:run).once.with(ffmpeg, '-i', original_video_path, '-vframes', '1', '-ss', '10', '-f', 'image2', '-vcodec', 'mjpeg', '-y', frame_path('png'))
        process_video{record_frame(:codec => 'mjpeg')}
      end

      it "should use the mjpeg codec by default for jpg images" do
        video_style :output, :format => 'jpg'
        Bulldog.expects(:run).once.with(ffmpeg, '-i', original_video_path, '-vframes', '1', '-ss', '10', '-f', 'image2', '-vcodec', 'mjpeg', '-y', frame_path('jpg'))
        process_video{record_frame}
      end

      it "should use the mjpeg codec by default for jpeg images" do
        video_style :output, :format => 'jpeg'
        Bulldog.expects(:run).once.with(ffmpeg, '-i', original_video_path, '-vframes', '1', '-ss', '10', '-f', 'image2', '-vcodec', 'mjpeg', '-y', frame_path('jpeg'))
        process_video{record_frame}
      end

      it "should use the png codec by default for png images" do
        video_style :output, :format => 'png'
        Bulldog.expects(:run).once.with(ffmpeg, '-i', original_video_path, '-vframes', '1', '-ss', '10', '-f', 'image2', '-vcodec', 'png', '-y', frame_path('png'))
        process_video{record_frame}
      end
    end
  end

  describe "encoding style attributes" do
    describe "video" do
      it "should interpret '30fps' as a frame rate of 30fps" do
        video_style :output, :video => '30fps'
        Bulldog.expects(:run).once.with(ffmpeg, '-i', original_video_path, '-r', '30', '-y', output_video_path)
        process_video{encode}
      end

      it "should interpret '30FPS' as a frame rate of 30fps" do
        video_style :output, :video => '30FPS'
        Bulldog.expects(:run).once.with(ffmpeg, '-i', original_video_path, '-r', '30', '-y', output_video_path)
        process_video{encode}
      end

      it "should interpret 628kbps as a video bit rate of 628kbps" do
        video_style :output, :video => '628kbps'
        Bulldog.expects(:run).once.with(ffmpeg, '-i', original_video_path, '-b', '628k', '-y', output_video_path)
        process_video{encode}
      end

      it "should interpret any other word as a video codec" do
        video_style :output, :video => 'libx264'
        Bulldog.expects(:run).once.with(ffmpeg, '-i', original_video_path, '-vcodec', 'libx264', '-y', output_video_path)
        process_video{encode}
      end

      it "should combine multiple attributes of the video stream as given" do
        video_style :output, :video => 'libx264 30fps 628kbps'
        Bulldog.expects(:run).once.with(ffmpeg, '-i', original_video_path, '-vcodec', 'libx264', '-r', '30', '-b', '628k', '-y', output_video_path)
        process_video{encode}
      end
    end

    describe "audio" do
      it "should interpret '44100Hz' as a sampling frequency of 44100Hz" do
        video_style :output, :audio => '44100Hz'
        Bulldog.expects(:run).once.with(ffmpeg, '-i', original_video_path, '-ar', '44100', '-y', output_video_path)
        process_video{encode}
      end

      it "should interpret '44100hz' as a sampling frequency of 44100Hz" do
        video_style :output, :audio => '44100hz'
        Bulldog.expects(:run).once.with(ffmpeg, '-i', original_video_path, '-ar', '44100', '-y', output_video_path)
        process_video{encode}
      end

      it "should interpret '64kbps' as a sampling frequency of 64kbps" do
        video_style :output, :audio => '64kbps'
        Bulldog.expects(:run).once.with(ffmpeg, '-i', original_video_path, '-ab', '64k', '-y', output_video_path)
        process_video{encode}
      end

      it "should interpret 'mono' as 1 channel" do
        video_style :output, :audio => 'mono'
        Bulldog.expects(:run).once.with(ffmpeg, '-i', original_video_path, '-ac', '1', '-y', output_video_path)
        process_video{encode}
      end

      it "should interpret 'stereo' as 2 channels" do
        video_style :output, :audio => 'stereo'
        Bulldog.expects(:run).once.with(ffmpeg, '-i', original_video_path, '-ac', '2', '-y', output_video_path)
        process_video{encode}
      end

      it "should interpret any other word as an audio codec" do
        video_style :output, :audio => 'libfaac'
        Bulldog.expects(:run).once.with(ffmpeg, '-i', original_video_path, '-acodec', 'libfaac', '-y', output_video_path)
        process_video{encode}
      end

      it "should combine multiple attributes of the audio stream as given" do
        video_style :output, :audio => 'libfaac 44100Hz 64kbps'
        Bulldog.expects(:run).once.with(ffmpeg, '-i', original_video_path, '-acodec', 'libfaac', '-ar', '44100', '-ab', '64k', '-y', output_video_path)
        process_video{encode}
      end
    end

    describe "video_codec" do
      it "should set the video codec" do
        video_style :output, :video_codec => 'libx264'
        Bulldog.expects(:run).once.with(ffmpeg, '-i', original_video_path, '-vcodec', 'libx264', '-y', output_video_path)
        process_video{encode}
      end
    end

    describe "frame_rate" do
      it "should set the frame rate" do
        video_style :output, :frame_rate => 30
        Bulldog.expects(:run).once.with(ffmpeg, '-i', original_video_path, '-r', '30', '-y', output_video_path)
        process_video{encode}
      end
    end

    describe "video_bit_rate" do
      it "should set the video bit rate" do
        video_style :output, :video_bit_rate => '64k'
        Bulldog.expects(:run).once.with(ffmpeg, '-i', original_video_path, '-b', '64k', '-y', output_video_path)
        process_video{encode}
      end
    end

    describe "audio_codec" do
      it "should set the audio codec" do
        video_style :output, :audio_codec => 'libfaac'
        Bulldog.expects(:run).once.with(ffmpeg, '-i', original_video_path, '-acodec', 'libfaac', '-y', output_video_path)
        process_video{encode}
      end
    end

    describe "sampling_rate" do
      it "should set the sampling rate" do
        video_style :output, :sampling_rate => 44100
        Bulldog.expects(:run).once.with(ffmpeg, '-i', original_video_path, '-ar', '44100', '-y', output_video_path)
        process_video{encode}
      end
    end

    describe "audio_bit_rate" do
      it "should set the audio bit rate" do
        video_style :output, :audio_bit_rate => '64k'
        Bulldog.expects(:run).once.with(ffmpeg, '-i', original_video_path, '-ab', '64k', '-y', output_video_path)
        process_video{encode}
      end
    end

    describe "channels" do
      it "should set the number of channels" do
        video_style :output, :channels => 2
        Bulldog.expects(:run).once.with(ffmpeg, '-i', original_video_path, '-ac', '2', '-y', output_video_path)
        process_video{encode}
      end
    end

    describe "video_preset" do
      it "should set a video preset" do
        video_style :output, :video_preset => 'one'
        Bulldog.expects(:run).once.with(ffmpeg, '-i', original_video_path, '-vpre', 'one', '-y', output_video_path)
        process_video{encode}
      end

      it "should allow setting more than one video preset" do
        video_style :output, :video_preset => ['one', 'two']
        Bulldog.expects(:run).once.with(ffmpeg, '-i', original_video_path, '-vpre', 'one', '-vpre', 'two', '-y', output_video_path)
        process_video{encode}
      end
    end

    describe "audio_preset" do
      it "should set a audio preset" do
        video_style :output, :audio_preset => 'one'
        Bulldog.expects(:run).once.with(ffmpeg, '-i', original_video_path, '-apre', 'one', '-y', output_video_path)
        process_video{encode}
      end

      it "should allow setting more than one audio preset" do
        video_style :output, :audio_preset => ['one', 'two']
        Bulldog.expects(:run).once.with(ffmpeg, '-i', original_video_path, '-apre', 'one', '-apre', 'two', '-y', output_video_path)
        process_video{encode}
      end
    end

    describe "subtitle_preset" do
      it "should set a subtitle preset" do
        video_style :output, :subtitle_preset => 'one'
        Bulldog.expects(:run).once.with(ffmpeg, '-i', original_video_path, '-spre', 'one', '-y', output_video_path)
        process_video{encode}
      end

      it "should allow setting more than one subtitle preset" do
        video_style :output, :subtitle_preset => ['one', 'two']
        Bulldog.expects(:run).once.with(ffmpeg, '-i', original_video_path, '-spre', 'one', '-spre', 'two', '-y', output_video_path)
        process_video{encode}
      end
    end

    describe "size" do
      it "should set the video size" do
        video_style :output, :size => '400x300'
        Bulldog.expects(:run).once.with(ffmpeg, '-i', original_video_path, '-s', '400x300', '-y', output_video_path)
        process_video{encode}
      end

      it "should maintain the original aspect ratio" do
        video_style :output, :size => '600x600'
        Bulldog.expects(:run).once.with(ffmpeg, '-i', original_video_path, '-s', '600x450', '-y', output_video_path)
        process_video{encode}
      end

      it "should maintain the original aspect ratio when the style size is overridden"
    end

    describe "num_channels" do
      it "should set the number of channels" do
        video_style :output, :channels => 2
        Bulldog.expects(:run).once.with(ffmpeg, '-i', original_video_path, '-ac', '2', '-y', output_video_path)
        process_video{encode}
      end
    end

    describe "deinterlaced" do
      it "should set the deinterlace flag" do
        video_style :output, :deinterlaced => true
        Bulldog.expects(:run).once.with(ffmpeg, '-i', original_video_path, '-deinterlace', '-y', output_video_path)
        process_video{encode}
      end
    end

    describe "pixel_format" do
      it "should set the pixel format" do
        video_style :output, :pixel_format => 'yuv420p'
        Bulldog.expects(:run).once.with(ffmpeg, '-i', original_video_path, '-pix_fmt', 'yuv420p', '-y', output_video_path)
        process_video{encode}
      end
    end

    describe "b_strategy" do
      it "should set the b-strategy" do
        video_style :output, :b_strategy => 1
        Bulldog.expects(:run).once.with(ffmpeg, '-i', original_video_path, '-b_strategy', '1', '-y', output_video_path)
        process_video{encode}
      end
    end

    describe "buffer_size" do
      it "should set the video buffer verifier buffer size" do
        video_style :output, :buffer_size => '2M'
        Bulldog.expects(:run).once.with(ffmpeg, '-i', original_video_path, '-bufsize', '2M', '-y', output_video_path)
        process_video{encode}
      end
    end

    describe "coder" do
      it "should set the coder" do
        video_style :output, :coder => 'ac'
        Bulldog.expects(:run).once.with(ffmpeg, '-i', original_video_path, '-coder', 'ac', '-y', output_video_path)
        process_video{encode}
      end
    end

    describe "verbosity" do
      it "should set the verbosity" do
        video_style :output, :verbosity => 1
        Bulldog.expects(:run).once.with(ffmpeg, '-i', original_video_path, '-v', '1', '-y', output_video_path)
        process_video{encode}
      end
    end

    describe "flags" do
      it "should set the flags" do
        video_style :output, :flags => '+loop'
        Bulldog.expects(:run).once.with(ffmpeg, '-i', original_video_path, '-flags', '+loop', '-y', output_video_path)
        process_video{encode}
      end
    end
  end

  describe "#use_threads" do
    it "should set the number of threads" do
      video_style :output
      Bulldog.expects(:run).once.with(ffmpeg, '-i', original_video_path, '-threads', '2', '-y', output_video_path)
      process_video{use_threads 2}
    end
  end
end
