require 'spec_helper'

describe Attachment::Video do
  it_should_behave_like_an_attachment_with_dimensions(
    :type => :video,
    :missing_dimensions => [2, 2],
    :file_40x30 => 'test-40x30x1.mov',
    :file_20x10 => 'test-20x10x1.mov'
  )

  describe "when instantiated" do
    use_model_class(:Thing, :attachment_file_name => :string)

    before do
      Thing.has_attachment :attachment do
        style :double, :size => '80x60'
        style :filled, :size => '60x60', :filled => true
        style :unfilled, :size => '120x120'
        default_style :double
      end
      @thing = Thing.new(:attachment => uploaded_file('test-40x30x1.mov'))
    end

    describe "#dimensions" do
      it "should round calculated dimensions down to the nearest multiple of 2" do
        Thing.has_attachment :attachment do
          style :odd, :size => '59x59', :filled => true
        end
        @thing.attachment.dimensions(:odd).should == [58, 58]
      end
    end

    describe "#duration" do
      it "should return the duration of the given style" do
        @thing.attachment.duration(:original).should == 1.second
        # TODO: Add video slicing, and make duration return the correct duration.
        @thing.attachment.duration(:double).should == 1.second
      end

      it "should use the default style if no style is given"
    end

    describe "#video_tracks" do
      it "should return the video tracks of the given style" do
        @thing.attachment.video_tracks(:original).should have(1).video_track
        @thing.attachment.video_tracks(:original).first.dimensions.should == [40, 30]
      end

      it "should take into account filledness of the style" do
        @thing.attachment.video_tracks(:original).should have(1).video_track
        @thing.attachment.video_tracks(:original).first.dimensions.should == [40, 30]
      end

      it "should use the default style if no style is given" do
        @thing.attachment.video_tracks.should have(1).video_track
        @thing.attachment.video_tracks.first.dimensions.should == [80, 60]
      end
    end

    describe "#audio_tracks" do
      it "should return the audio tracks of the given style" do
        @thing.attachment.audio_tracks(:original).should have(1).audio_track
        @thing.attachment.audio_tracks(:original).first.duration.should == 1
      end

      it "should use the default style if no style is given" do
        @thing.attachment.audio_tracks.should have(1).audio_track
        @thing.attachment.audio_tracks.first.duration.should == 1
      end
    end
  end

  describe "when the duration is stored" do
    use_model_class(:Thing, :attachment_file_name => :string, :attachment_duration => :integer)

    before do
      Thing.has_attachment :attachment do
        type :video
        style :double, :size => '80x60'
      end
    end

    describe "when the stored values are hacked, and the record reinstantiated" do
      before do
        @thing = Thing.create!(:attachment => uploaded_file('test-40x30x1.mov'))
        Thing.update_all({:attachment_duration => 2}, {:id => @thing.id})
        @thing = Thing.find(@thing.id)
      end

      it "should use the stored duration for the original" do
        @thing.attachment.duration(:original).should == 2
      end

      it "should calculate the duration of other styles from that of the original" do
        @thing.attachment.duration(:double).should == 2
      end
    end
  end

  describe "when the duration is not stored" do
    use_model_class(:Thing, :attachment_file_name => :string)

    before do
      Thing.has_attachment :attachment do
        type :video
        style :double, :size => '80x60'
      end
    end

    describe "when the file is missing" do
      before do
        @thing = Thing.create!(:attachment => uploaded_file('test-40x30x1.mov'))
        File.unlink(@thing.attachment.path(:original))
        @thing = Thing.find(@thing.id)
      end

      describe "#duration" do
        it "should return 0 for the original style" do
          @thing.attachment.duration(:original).should == 0
        end

        it "should calculate the duration of other styles from that of the original" do
          @thing.attachment.duration(:double).should == 0
        end
      end

      describe "#video_tracks" do
        it "should return no video tracks" do
          @thing.attachment.video_tracks.should have(0).video_tracks
        end
      end

      describe "#audio_tracks" do
        it "should return no audio tracks" do
          @thing.attachment.audio_tracks.should have(0).audio_tracks
        end
      end
    end
  end
end
