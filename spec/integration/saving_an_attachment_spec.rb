require 'spec_helper'

describe "Saving an attachment" do
  use_model_class(:Thing, :value => :integer)

  #
  # The list of files this process has open.
  #
  def open_files
    `lsof -p #{Process.pid} -F n`.split(/\n/).sort
  end

  it "should not leave any file handles left open" do
    tmp = temporary_directory
    Thing.has_attachment :photo do
      path "#{tmp}/:style.png"
      style :small, :size => '10x10'
      process :after => :save do
        resize
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
