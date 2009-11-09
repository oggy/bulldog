require 'spec_helper'

describe "Processing video attachments" do
  set_up_model_class :Thing do |t|
    t.string :video_file_name
    t.string :still_frame_file_name
  end

  before do
    spec = self
    Thing.class_eval do
      has_attachment :video do
        style :encoded, :format => 'ogg',
                        :video => 'libtheora 640x360 24fps', :audio => 'libvorbis 44100Hz 128kbps',
                        :pixel_format => 'yuv420p'
        style :frame,   :format => 'jpg'
        path "#{spec.temporary_directory}/:id.:style.:extension"

        # TODO: fix problem with :after => save running when the
        # attachment wasn't changed, and process on after save.
        process :on => :process, :styles => [:encoded]
        process :on => :process, :styles => [:frame] do
          record_frame(:assign_to => :still_frame)
        end
      end

      has_attachment :still_frame do
        style :thumbnail, :format => 'png'
        path "#{spec.temporary_directory}/:id-still_frame.:style.:extension"
        process :on => :process
      end
    end

    @file = open("#{ROOT}/spec/data/test.mov")
    @thing = Thing.new(:video => @file)
  end

  after do
    @file.close
  end

  def original_video_path
    "#{temporary_directory}/#{@thing.id}.original.mov"
  end

  def encoded_video_path
    "#{temporary_directory}/#{@thing.id}.encoded.ogg"
  end

  def original_frame_path
    "#{temporary_directory}/#{@thing.id}-still_frame.original.jpg"
  end

  def frame_thumbnail_path
    "#{temporary_directory}/#{@thing.id}-still_frame.thumbnail.png"
  end

  it "should not yet have a still frame assigned" do
    @thing.still_frame.should be_blank
  end

  describe "when the record is saved" do
    before do
      @thing.save
      @thing.process_attachment(:video, :process)
      @thing.process_attachment(:still_frame, :process)
    end

    it "should encode the video" do
      File.should exist(original_video_path)
      File.should exist(encoded_video_path)
    end

    it "should assign to the still frame" do
      @thing.still_frame.should_not be_blank
    end

    it "should create the thumbnail" do
      File.should exist(original_frame_path)
      File.should exist(frame_thumbnail_path)
    end
  end
end
