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
    set_up_model_class :Thing do |t|
      t.string :photo_file_name
    end

    configure_attachment do |spec|
      path "#{spec.temporary_directory}/:id.:style.jpg"
      style :small, {}
      style :png, :format => :png
    end

    def original_path
      "#{temporary_directory}/#{@thing.id}.original.jpg"
    end

    def small_path
      "#{temporary_directory}/#{@thing.id}.small.jpg"
    end

    def png_path
      "#{temporary_directory}/#{@thing.id}.png.png"
    end

    it "should return the path of the given style, interpolated from the path template" do
      @thing.photo = uploaded_file('test.jpg', '')
      @thing.stubs(:id).returns(5)
      @thing.photo.path(:original).should == original_path
      @thing.photo.path(:small).should == small_path
    end

    describe "when the :extension interpolation key is used" do
      before do
        spec = self
        Thing.attachment_reflections[:photo].configure do
          path "#{spec.temporary_directory}/:id.:style.:extension"
        end
        @thing.photo = uploaded_file('test.jpg', '')
      end

      it "should use the extension of the original file for the original style" do
        @thing.photo.path(:original).should == "#{temporary_directory}/#{@thing.id}.original.jpg"
      end
      it "should use the format of the output file for other styles" do
        @thing.photo.path(:png).should == "#{temporary_directory}/#{@thing.id}.png.png"
      end
    end

    describe "when the :extension interpolation key is not used" do
      before do
        spec = self
        Thing.attachment_reflections[:photo].configure do
          path "#{spec.temporary_directory}/:id.:style.xyz"
        end
        @thing.photo = uploaded_file('test.jpg', '')
      end

      it "should use the extension of the path template for the original style" do
        @thing.photo.path(:original).should == "#{temporary_directory}/#{@thing.id}.original.xyz"
      end

      it "should use the extension of the path template for other styles" do
        @thing.photo.path(:png).should == "#{temporary_directory}/#{@thing.id}.png.xyz"
      end
    end

    describe "when no style is given" do
      configure_attachment do
        path "/tmp/:id.:style.jpg"
        style :small, {}
        default_style :small
      end

      it "should default to the attachment's default style" do
        @thing.stubs(:id).returns(5)
        @thing.photo = uploaded_file('test.jpg', '')
        @thing.photo.path.should == "/tmp/5.small.jpg"
      end
    end
  end

  describe "#url" do
    set_up_model_class :Thing do |t|
      t.string :photo_file_name
    end

    configure_attachment do
      path "/tmp/:id.:style.jpg"
      url "/assets/:id.:style.jpg"
      style :small
      style :png, :format => :png
    end

    it "should return the url of the given style, interpolated from the url template" do
      @thing.photo = uploaded_file('test.jpg', '')
      @thing.stubs(:id).returns(5)
      @thing.photo.url(:original).should == "/assets/5.original.jpg"
      @thing.photo.url(:small).should == "/assets/5.small.jpg"
    end

    describe "when the :extension interpolation key is used" do
      before do
        spec = self
        Thing.attachment_reflections[:photo].configure do
          path "/tmp/:id.:style.:extension"
          url "/assets/:id.:style.:extension"
        end
        @thing.photo = uploaded_file('test.jpg', '')
      end

      it "should use the extension of the original file for the original style" do
        @thing.photo.url(:original).should == "/assets/#{@thing.id}.original.jpg"
      end

      it "should use the format of the output file for the other styles" do
        @thing.photo.url(:png).should == "/assets/#{@thing.id}.png.png"
      end
    end

    describe "when the :extension interpolation key is not used" do
      before do
        spec = self
        Thing.attachment_reflections[:photo].configure do
          path "/tmp/:id.:style.xyz"
          url "/assets/:id.:style.xyz"
        end
        @thing.photo = uploaded_file('test.jpg', '')
      end

      it "should use the extension of the url template for the original style" do
        @thing.photo.url(:original).should == "/assets/#{@thing.id}.original.xyz"
      end

      it "should use the extension of the url template for the other styles" do
        @thing.photo.url(:png).should == "/assets/#{@thing.id}.png.xyz"
      end
    end

    describe "when no style is given" do
      configure_attachment do
        url "/assets/:id.:style.jpg"
        style :small, {}
        default_style :small
      end

      it "should default to the attachment's default style" do
        @thing.stubs(:id).returns(5)
        @thing.photo = uploaded_file('test.jpg', '')
        @thing.photo.url.should == "/assets/5.small.jpg"
      end
    end
  end

  describe "#file_size" do
    set_up_model_class :Thing

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
      @thing = Thing.new(:photo => small_uploaded_file('test.jpg', '...'))
    end

    it "should return the size of the file" do
      @thing.photo.file_size.should == 3
    end

    describe "when the value is a saved file" do
      it "should return the size of the file" do
        @thing.save
        @thing = Thing.find(@thing.id)
        with_temporary_file(original_path, '...') do |path|
          @thing.photo.file_size.should == 3
        end
      end
    end
  end

  describe "#file_name" do
    set_up_model_class :Thing do |t|
      t.string :photo_file_name
    end

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
      @thing = Thing.new(:photo => small_uploaded_file('test.jpg', '...'))
    end

    it "should return the original base name of the file" do
      @thing.photo.file_name.should == 'test.jpg'
    end

    describe "when the value is a saved file" do
      it "should return the original base name of the file" do
        @thing.save
        @thing = Thing.find(@thing.id)
        with_temporary_file(original_path, '...') do |path|
          @thing.photo.file_name.should == 'test.jpg'
        end
      end
    end
  end

  describe "#process" do
    set_up_model_class :Thing do |t|
      t.string
    end

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
      thing = Thing.new(:photo => uploaded_file)
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
      thing = Thing.new(:photo => uploaded_file)
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
      thing = Thing.new(:photo => uploaded_file)
      thing.photo.process(:test_event)
      styles.should be_a(StyleSet)
      styles.map(&:name).should == [:small]
    end
  end

  describe "storable attributes" do
    set_up_model_class :Thing do |t|
      t.string :photo_file_name
      t.integer :photo_file_size
      t.string :photo_content_type
    end

    before do
      Thing.has_attachment :photo
      @thing = Thing.new(:photo => uploaded_file('test.jpg', "\xff\xd8"))
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
