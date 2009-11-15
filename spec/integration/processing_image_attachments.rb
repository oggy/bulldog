require 'spec_helper'

describe "Processing image attachments" do
  use_model_class(:Thing,
                  :width => :integer,
                  :height => :integer)

  def identify
    Bulldog::Processor::ImageMagick.identify_command
  end

  before do
    tmp = temporary_directory
    Thing.has_attachment :photo do
      path "#{tmp}/:id.:style.png"
      style :small, {:size => '10x10!'}
      style :large, {:size => '1000x1000!'}

      process :before => :save do
        width, height = dimensions
        record.width = width
        record.height = height
      end

      process :on => :resize do
        resize
      end
    end
    @thing = Thing.new
    @thing.stubs(:id).returns(5)
    @file = small_uploaded_file(:size => "40x30")
  end

  def small_uploaded_file(options={})
    tmp_path = "#{temporary_directory}/small_uploaded_file.tmp.png"
    create_image(tmp_path, options)
    content = File.read(tmp_path)
    File.unlink(tmp_path)

    io = ActionController::UploadedStringIO.new(content)
    io.original_path = "tmp.png"
    io.content_type = 'image/png'
    io
  end

  after do
    @file.close
  end

  def path(style)
    "#{temporary_directory}/5.#{style}.png"
  end

  it "should run the after_save process after saving" do
    @thing.update_attributes(:photo => @file)
    @thing.width.should == 40
    @thing.height.should == 30
  end

  it "should process the attachment when the processor is run" do
    File.exist?(path(:original)).should be_false
    File.exist?(path(:small)).should be_false
    File.exist?(path(:large)).should be_false

    @thing.update_attributes(:photo => @file).should be_true
    @thing.process_attachment(:photo, :resize)

    `"#{identify}" -format "%w %h" "#{path(:original)}"`.chomp.should == '40 30'
    `"#{identify}" -format "%w %h" "#{path(:small)}"`.chomp.should == '10 10'
    `"#{identify}" -format "%w %h" "#{path(:large)}"`.chomp.should == '1000 1000'
  end
end
