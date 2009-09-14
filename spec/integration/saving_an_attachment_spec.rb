require 'spec_helper'

describe "Saving an attachment" do
  set_up_model_class :Thing do |t|
    t.integer :value
  end

  #
  # The list of files this process has open.
  #
  def open_files
    `lsof -p #{Process.pid}`.split(/\n/).sort
  end

  it "should not leave any file handles left open" do
    tmp = temporary_directory
    Thing.has_attachment :photo do
      paths "#{tmp}/:style.png"
      style :small, :size => '10x10'
      after :save, :with => :image_magick do
        resize(styles)
      end
    end

    path = create_image("#{temporary_directory}/tmp.jpg")
    open(path) do |file|
      @initial_open_files = open_files
      thing = Thing.new(:photo => file)
      thing.save.should be_true
      open_files.should == @initial_open_files
    end
  end
end