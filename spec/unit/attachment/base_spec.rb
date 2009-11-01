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
    set_up_model_class :Thing

    configure_attachment do |spec|
      path "#{spec.temporary_directory}/:id.:style.jpg"
      style :small, {}
      store_file_attributes :file_name
    end

    def original_path
      "#{temporary_directory}/#{@thing.id}.original.jpg"
    end

    def small_path
      "#{temporary_directory}/#{@thing.id}.small.jpg"
    end

    it "should return the path of the given style, interpolated from the path template" do
      @thing.photo = uploaded_file('test.jpg', '')
      @thing.stubs(:id).returns(5)
      @thing.photo.path(:original).should == original_path
      @thing.photo.path(:small).should == small_path
    end

    describe "when no style is given" do
      configure_attachment do
        path "/tmp/:id.:style.jpg"
        style :small, {}
        default_style :small
      end

      it "should default to the default_style" do
        @thing.stubs(:id).returns(5)
        @thing.photo = uploaded_file('test.jpg', '')
        @thing.photo.path.should == "/tmp/5.small.jpg"
      end
    end
  end

  describe "#url" do
    set_up_model_class :Thing

    describe "when not explicitly set, and the path is under the docroot" do
      configure_attachment do
        path ":rails_root/public/images/:id.:style.jpg"
        style :small, {}
        store_file_attributes :file_name
      end

      it "should return the #path relative to the docroot" do
        with_temporary_constant_value Object, :RAILS_ROOT, 'RAILS_ROOT' do
          @thing.photo = uploaded_file('test.jpg', '')
          @thing.stubs(:id).returns(5)
          @thing.photo.url(:original).should == "/images/5.original.jpg"
          @thing.photo.url(:small).should == "/images/5.small.jpg"
        end
      end
    end

    describe "when not explicitly set, and the path is not under the docroot" do
      configure_attachment do
        path "/tmp/:id.:style.jpg"
        style :small, {}
        store_file_attributes :file_name
      end

      it "should raise an error" do
        @thing.photo = uploaded_file('test.jpg', '')
        @thing.stubs(:id).returns(5)
        lambda{@thing.photo.url(:original)}.should raise_error
        lambda{@thing.photo.url(:small)}.should raise_error
      end
    end

    describe "when explicitly set" do
      configure_attachment do
        path "/tmp/:id.:style.jpg"
        url "/assets/:id.:style.jpg"
        style :small, {}
        store_file_attributes :file_name
      end

      it "should return the url of the given style, interpolated from the url template" do
        @thing.photo = uploaded_file('test.jpg', '')
        @thing.stubs(:id).returns(5)
        @thing.photo.url(:original).should == "/assets/5.original.jpg"
        @thing.photo.url(:small).should == "/assets/5.small.jpg"
      end
    end

    describe "when no style is given" do
      configure_attachment do
        url "/assets/:id.:style.jpg"
        style :small, {}
        default_style :small
      end

      it "should default to the default_style" do
        @thing.stubs(:id).returns(5)
        @thing.photo = uploaded_file('test.jpg', '')
        @thing.photo.url.should == "/assets/5.small.jpg"
      end
    end
  end

  describe "#size" do
    set_up_model_class :Thing

    configure_attachment do |spec|
      path "#{spec.temporary_directory}/:id.:style.jpg"
      style :small, {}
      store_file_attributes :file_name
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

    describe "when the value is a small uploaded file (StringIO)" do
      it "should return the content length of the uploaded data" do
        @thing.photo = small_uploaded_file('test.jpg', '...')
        @thing.photo.size.should == 3
      end
    end

    describe "when the value is a large uploaded file (Tempfile)" do
      it "should return the content length of the uploaded data" do
        @thing.photo = large_uploaded_file('test.jpg', '...')
        @thing.photo.size.should == 3
      end
    end

    describe "when the value is a File object" do
      it "should return the size of the file" do
        with_temporary_file("#{temporary_directory}/test.jpg", '...') do |path|
          open(path) do |file|
            @thing.photo = file
            @thing.photo.size.should == 3
          end
        end
      end
    end

    describe "when the value is an existing file (UnopenedFile)" do
      it "should return the size of the file" do
        @thing.save
        @thing = Thing.find(@thing.id)
        with_temporary_file(original_path, '...') do |path|
          @thing.photo.size.should == 3
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

  describe "#set_file_attributes" do
    set_up_model_class :Thing do |t|
      t.string :photo_file_name
      t.string :photo_content_type
      t.integer :photo_file_size
      t.datetime :photo_updated_at
    end

    before do
      Thing.has_attachment :photo
      Thing.attachment_reflections[:photo].stubs(:file_attributes).returns(
                                                                           :file_name => :photo_file_name,
                                                                           :content_type => :photo_content_type,
                                                                           :file_size => :photo_file_size,
                                                                           :updated_at => :photo_updated_at
                                                                           )
    end

    describe "when the value is a small uploaded file (StringIO)" do
      it "should set the file attributes" do
        file = small_uploaded_file('test.jpg', "\xff\xd8")
        file.should be_a(StringIO)  # sanity check
        thing = Thing.new(:photo => file)
        thing.photo_file_name.should == 'test.jpg'
        thing.photo_content_type.split(/;/).first == 'image/jpeg'
        thing.photo_file_size.should == 2
        thing.photo_updated_at.should == Time.now
      end
    end

    describe "when the value is a large uploaded file (Tempfile)" do
      it "should set the file attributes" do
        file = large_uploaded_file('test.jpg', "\xff\xd8")
        file.should be_a(Tempfile)  # sanity check
        thing = Thing.new(:photo => file)
        thing.photo_file_name.should == 'test.jpg'
        thing.photo_content_type.split(/;/).first == 'image/jpeg'
        thing.photo_file_size.should == 2
        thing.photo_updated_at.should == Time.now
      end
    end
  end
end
