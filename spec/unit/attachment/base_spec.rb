require 'spec_helper'

describe Attachment::Base do
  def self.configure_attachment(&block)
    before do
      spec = self
      Thing.has_attachment :photo do
        instance_exec(spec, &block)
      end
      @thing = Thing.new
    end
  end

  describe "#path" do
    use_model_class(:Thing, :photo_file_name => :string)

    configure_attachment do |spec|
      path "#{spec.temporary_directory}/:style.jpg"
      style :small, {}
      style :png, :format => :png
    end

    def original_path
      "#{temporary_directory}/original.jpg"
    end

    def small_path
      "#{temporary_directory}/small.jpg"
    end

    def png_path
      "#{temporary_directory}/png.png"
    end

    it "should return the path of the given style, interpolated from the path template" do
      @thing.photo = test_image_file
      @thing.stubs(:id).returns(5)
      @thing.photo.path(:original).should == original_path
      @thing.photo.path(:small).should == small_path
    end

    describe "when the :extension interpolation key is used" do
      before do
        spec = self
        Thing.attachment_reflections[:photo].configure do
          path "#{spec.temporary_directory}/:style.:extension"
        end
        @thing.photo = test_image_file
      end

      it "should use the extension of the original file for the original style" do
        @thing.photo.path(:original).should == "#{temporary_directory}/original.jpg"
      end
      it "should use the format of the output file for other styles" do
        @thing.photo.path(:png).should == "#{temporary_directory}/png.png"
      end
    end

    describe "when the :extension interpolation key is not used" do
      before do
        spec = self
        Thing.attachment_reflections[:photo].configure do
          path "#{spec.temporary_directory}/:style.xyz"
        end
        @thing.photo = test_image_file
      end

      it "should use the extension of the path template for the original style" do
        @thing.photo.path(:original).should == "#{temporary_directory}/original.xyz"
      end

      it "should use the extension of the path template for other styles" do
        @thing.photo.path(:png).should == "#{temporary_directory}/png.xyz"
      end
    end

    describe "when no style is given" do
      configure_attachment do
        path "/tmp/:style.jpg"
        style :small, {}
        default_style :small
      end

      it "should default to the attachment's default style" do
        @thing.photo = test_image_file
        @thing.photo.path.should == "/tmp/small.jpg"
      end
    end
  end

  describe "#url" do
    use_model_class(:Thing, :photo_file_name => :string)

    configure_attachment do
      path "/tmp/:style.jpg"
      url "/assets/:style.jpg"
      style :small
      style :png, :format => :png
    end

    it "should return the url of the given style, interpolated from the url template" do
      @thing.photo = test_image_file
      @thing.photo.url(:original).should == "/assets/original.jpg"
      @thing.photo.url(:small).should == "/assets/small.jpg"
    end

    describe "when the :extension interpolation key is used" do
      before do
        spec = self
        Thing.attachment_reflections[:photo].configure do
          path "/tmp/:style.:extension"
          url "/assets/:style.:extension"
        end
        @thing.photo = test_image_file
      end

      it "should use the extension of the original file for the original style" do
        @thing.photo.url(:original).should == "/assets/original.jpg"
      end

      it "should use the format of the output file for the other styles" do
        @thing.photo.url(:png).should == "/assets/png.png"
      end
    end

    describe "when the :extension interpolation key is not used" do
      before do
        spec = self
        Thing.attachment_reflections[:photo].configure do
          path "/tmp/:style.xyz"
          url "/assets/:style.xyz"
        end
        @thing.photo = test_image_file
      end

      it "should use the extension of the url template for the original style" do
        @thing.photo.url(:original).should == "/assets/original.xyz"
      end

      it "should use the extension of the url template for the other styles" do
        @thing.photo.url(:png).should == "/assets/png.xyz"
      end
    end

    describe "when no style is given" do
      configure_attachment do
        url "/assets/:style.jpg"
        style :small, {}
        default_style :small
      end

      it "should default to the attachment's default style" do
        @thing.photo = test_image_file
        @thing.photo.url.should == "/assets/small.jpg"
      end
    end
  end

  describe "#file_size" do
    use_model_class(:Thing)

    configure_attachment do |spec|
      path "#{spec.temporary_directory}/:id.:style.jpg"
      style :small, {}
    end

    def original_path
      "#{temporary_directory}/#{@thing.id}.original.jpg"
    end

    def with_temporary_file(path, content)
      FileUtils.mkdir_p File.dirname(path)
      open(path, 'w'){|f| f.print '...'}
      begin
        yield path
      ensure
        File.delete(path)
      end
    end

    before do
      @thing = Thing.new(:photo => test_image_file)
    end

    it "should return the size of the file" do
      @thing.photo.file_size.should == File.size(test_image_path)
    end
  end

  describe "#file_name" do
    use_model_class(:Thing, :photo_file_name => :string)

    configure_attachment do |spec|
      path "#{spec.temporary_directory}/:id.:style.jpg"
      style :small, {}
      store_attributes :file_name
    end

    def original_path
      "#{temporary_directory}/#{@thing.id}.original.jpg"
    end

    def with_temporary_file(path, content)
      FileUtils.mkdir_p File.dirname(path)
      open(path, 'w'){|f| f.print '...'}
      begin
        yield path
      ensure
        File.delete(path)
      end
    end

    before do
      @thing = Thing.new(:photo => test_image_file)
    end

    it "should return the original base name of the file" do
      @thing.photo.file_name.should == File.basename(test_image_path)
    end
  end

  def with_test_processor(options, &block)
    test_processor_class = Class.new(Processor::Base) do
      define_method :process do
        if options[:error]
          record.errors.add name, "error"
        end
      end
    end
    with_temporary_constant_value(Processor, :Test, test_processor_class, &block)
  end

  describe "#process" do
    use_model_class(:Thing)

    use_temporary_constant_value Processor, :Test do
      Class.new(Processor::Base)
    end

    it "should use the default processor if no processor was specified" do
      context = nil
      Thing.has_attachment :photo do
        style :normal
        process :on => :test_event do
          context = self
        end
      end
      thing = Thing.new(:photo => test_image_file)
      thing.photo.stubs(:default_processor_type).returns(:test)
      thing.photo.process(:test_event)
      context.should be_a(Processor::Test)
    end

    it "should use the configured processor if one was specified" do
      context = nil
      Thing.has_attachment :photo do
        style :normal
        process :on => :test_event, :with => :test do
          context = self
        end
      end
      thing = Thing.new(:photo => test_image_file)
      thing.photo.process(:test_event)
      context.should be_a(Processor::Test)
    end

    it "should not run any processors if no attachment is set" do
      run = false
      Thing.has_attachment :photo do
        style :normal
        process :on => :test_event, :with => :test do
          run = true
        end
      end
      thing = Thing.new(:photo => nil)
      thing.photo.process(:test_event)
      run.should be_false
    end

    it "should run the processors only for the specified styles" do
      styles = nil
      Thing.has_attachment :photo do
        style :small, :size => '10x10'
        style :large, :size => '1000x1000'
        process :on => :test_event, :styles => [:small], :with => :test do
          styles = self.styles
        end
      end
      thing = Thing.new(:photo => test_image_file)
      thing.photo.process(:test_event)
      styles.should be_a(StyleSet)
      styles.map(&:name).should == [:small]
    end

    it "should return true if no errors were encountered" do
      with_test_processor(:error => false) do
        Thing.has_attachment :attachment do
          style :one
          process(:on => :event, :with => :test){}
        end
        thing = Thing.new(:attachment => test_empty_file)
        thing.attachment.process(:event).should be_true
      end
    end

    it "should return false if an error was encountered" do
      with_test_processor(:error => true) do
        Thing.has_attachment :attachment do
          style :one
          process(:on => :event, :with => :test){}
        end
        thing = Thing.new(:attachment => test_empty_file)
        thing.attachment.process(:event).should be_false
      end
    end
  end

  describe "#process!" do
    use_model_class(:Thing)

    it "should raise ActiveRecord::RecordInvalid if there are any errors present" do
      with_test_processor(:error => true) do
        Thing.has_attachment :attachment do
          style :one
          process :on => :event, :with => :test
        end
        thing = Thing.new(:attachment => test_empty_file)
        lambda{thing.attachment.process!(:event)}.should raise_error(ActiveRecord::RecordInvalid)
      end
    end

    it "should not raise ActiveRecord::RecordInvalid if there are no errors present" do
      with_test_processor(:error => false) do
        Thing.has_attachment :attachment do
          style :one
          process :on => :event, :with => :test
        end
        thing = Thing.new(:attachment => test_empty_file)
        lambda{thing.attachment.process!(:event)}.should_not raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end

  describe "storable attributes" do
    use_model_class(:Thing,
                    :photo_file_name => :string,
                    :photo_file_size => :integer,
                    :photo_content_type => :string)

    before do
      Thing.has_attachment :photo
      @thing = Thing.new(:photo => uploaded_file_with_content('test.jpg', "\xff\xd8"))
    end

    it "should set the stored attributes on assignment" do
      @thing.photo_file_name.should == 'test.jpg'
      @thing.photo_file_size.should == 2
      @thing.photo_content_type.should =~ /image\/jpeg/
    end

    it "should successfully roundtrip the stored attributes" do
      warp_ahead 1.minute
      @thing.save
      @thing = Thing.find(@thing.id)
      @thing.photo_file_name.should == 'test.jpg'
      @thing.photo_file_size.should == 2
      @thing.photo_content_type.should =~ /image\/jpeg/
    end
  end
end
