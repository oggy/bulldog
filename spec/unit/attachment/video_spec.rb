require 'spec_helper'

describe Attachment::Video do
  set_up_model_class :Thing do |t|
    t.integer :video_width
    t.integer :video_height
    t.float :video_aspect_ratio
    t.string :video_dimensions
    t.string :video_duration
  end

  before do
    Thing.has_attachment :video do
      # original video is 640x480.
      style :half, :size => '320x240'
      style :filled, :size => '60x60', :filled => true
      style :unfilled, :size => '120x120'
      default_style :half
    end
    @thing = Thing.new(:video => test_file)
  end

  def test_file
    video_path = "#{temporary_directory}/test.mov"
    FileUtils.cp("#{ROOT}/spec/data/test.mov", video_path)
    autoclose open(video_path)
  end

  def run(command)
    `#{command}`
    $?.success? or
      raise "command failed: #{command}"
  end

  describe "#dimensions" do
    it "should return 2x2 if the style is missing" do
      Thing.attachment_reflections[:video].configure do
        when_file_missing do
          use_attachment(:video)
        end
      end
      @thing.save.should be_true
      File.unlink(@thing.video.path(:original))
      @thing = Thing.find(@thing.id)
      @thing.video.dimensions(:original).should == [2, 2]
    end

    it "should return the width and height of the default style if no style name is given" do
      @thing.video.dimensions.should == [320, 240]
    end

    it "should return the width and height of the given style" do
      @thing.video.dimensions(:original).should == [640, 480]
      @thing.video.dimensions(:half).should == [320, 240]
    end

    it "should return the calculated width according to style filledness" do
      @thing.video.dimensions(:filled).should == [60, 60]
      @thing.video.dimensions(:unfilled).should == [120, 90]
    end

    it "should round calculated dimensions down to the nearest multiple of 2" do
      # TODO: ick!
      Thing.attachment_reflections[:video].styles[:filled][:size] = '59x59'
      @thing.video.dimensions(:filled).should == [58, 58]
    end

    it "should only invoke ffmpeg once"
    it "should log the result"
  end

  describe "#width" do
    it "should return the width of the default style if no style name is given" do
      @thing.video.width.should == 320
    end

    it "should return the width of the given style" do
      @thing.video.width(:original).should == 640
      @thing.video.width(:half).should == 320
    end
  end

  describe "#height" do
    it "should return the height of the default style if no style name is given" do
      @thing.video.height.should == 240
    end

    it "should return the height of the given style" do
      @thing.video.height(:original).should == 480
      @thing.video.height(:half).should == 240
    end
  end

  describe "#aspect_ratio" do
    it "should return the aspect ratio of the default style if no style name is given" do
      @thing.video.aspect_ratio.should be_close(4.0/3, 1e-5)
    end

    it "should return the aspect ratio of the given style" do
      @thing.video.aspect_ratio(:original).should be_close(4.0/3, 1e-5)
      @thing.video.aspect_ratio(:filled).should be_close(1, 1e-5)
    end
  end

  describe "#duration" do
    it "should return the duration of the original style if no style name is given" do
      @thing.video.duration.should == 1.second
    end

    it "should return the duration of the original style if a style name is given" do
      @thing.video.duration(:filled).should == 1.second
    end

    # TODO: make these work instead of the above
    it "should return the duration of the default style if no style name is given"
    it "should return the duration of the given style"
  end

  describe "#video_tracks" do
    it "should return the video tracks of the original style if no style name is given" do
      @thing.video.video_tracks.should have(1).video_track
      @thing.video.video_tracks.first.dimensions.should == [320, 240]
    end

    it "should return the video tracks of the target style if a style name is given" do
      @thing.video.video_tracks(:original).should have(1).video_track
      @thing.video.video_tracks(:original).first.dimensions.should == [640, 480]

      @thing.video.video_tracks(:filled).should have(1).video_track
      @thing.video.video_tracks(:filled).first.dimensions.should == [60, 60]
    end
  end

  describe "#audio_tracks" do
    it "should return the audio tracks of the original style if no style name is given" do
      @thing.video.video_tracks.should have(1).video_track
      @thing.video.video_tracks.first.dimensions.should == [320, 240]
    end

    it "should return the audio tracks of the target style if a style name is given" do
      @thing.video.video_tracks(:original).should have(1).video_track
      @thing.video.video_tracks(:original).first.dimensions.should == [640, 480]

      @thing.video.video_tracks(:filled).should have(1).video_track
      @thing.video.video_tracks(:filled).first.dimensions.should == [60, 60]
    end
  end

  describe "storable attributes" do
    it "should set the stored attributes on assignment" do
      @thing.video_width.should == 640
      @thing.video_height.should == 480
      @thing.video_aspect_ratio.should be_close(4.0/3, 1e-5)
      @thing.video_dimensions.should == '640x480'
    end

    describe "after roundtripping through the database" do
      before do
        @thing.save
        @thing = Thing.find(@thing.id)
      end

      it "should restore the stored attributes" do
        @thing.video_width.should == 640
        @thing.video_height.should == 480
        @thing.video_aspect_ratio.should be_close(4.0/3, 1e-5)
        @thing.video_dimensions.should == '640x480'
      end

      it "should recalculate the dimensions correctly" do
        @thing.video.dimensions(:filled).should == [60, 60]
        @thing.video.dimensions(:unfilled).should == [120, 90]
      end
    end
  end
end
