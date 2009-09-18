require 'spec_helper'

describe Attribute::Base do
  set_up_model_class :Thing do |t|
    t.string :photo_file_name
  end

  def self.configure_attachment(&block)
    before do
      spec = self
      Thing.has_attachment :photo do
        type :base
        instance_exec(spec, &block)
      end
      @thing = Thing.new
    end
  end

  def original_path
    "#{temporary_directory}/#{@thing.id}.original.jpg"
  end

  def small_path
    "#{temporary_directory}/#{@thing.id}.small.jpg"
  end

  def set_mtime(path, time)
    File.utime(File.atime(path), time, path)
    File.mtime(path)
  end

  def write_file(path, contents)
    open(path, 'w'){|f| f.write contents}
  end

  describe "#path" do
    configure_attachment do |spec|
      path "#{spec.temporary_directory}/:id.:style.jpg"
      style :small, {}
      store_file_attributes :file_name
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
    describe "when not explicitly set, and the path is under the docroot" do
      configure_attachment do
        path ":rails_root/public/images/:id.:style.jpg"
        style :small, {}
        store_file_attributes :file_name
      end

      it "should return the #path relative to the docroot" do
        @thing.photo = uploaded_file('test.jpg', '')
        @thing.stubs(:id).returns(5)
        @thing.photo.url(:original).should == "/images/5.original.jpg"
        @thing.photo.url(:small).should == "/images/5.small.jpg"
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
    configure_attachment do |spec|
      path "#{spec.temporary_directory}/:id.:style.jpg"
      style :small, {}
      store_file_attributes :file_name
    end

    def with_temporary_file(path, content)
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

    describe "when the value is nil" do
      it "should return nil" do
        @thing.photo.size.should be_nil
      end
    end
  end

  describe "before the attribute is assigned" do
    configure_attachment do |spec|
      path "#{spec.temporary_directory}/:id.:style.jpg"
      style :small, {}
      store_file_attributes :file_name
    end

    describe "when no attachment is present" do
      it "should make the query method return false" do
        @thing.photo?.should be_false
      end

      it "should return nil for the file attributes" do
        @thing.photo_file_name.should be_nil
      end

      it "should return nil for the path of all styles" do
        @thing.photo.path(:original).should be_nil
        @thing.photo.path(:small).should be_nil
      end

      it "should not appear changed" do
        @thing.photo.changed?.should be_false
      end
    end

    describe "when an attachment is present" do
      before do
        @thing.update_attributes(:photo => uploaded_file('test.jpg', '...')).should be_true
        @thing = Thing.find(@thing.id)
      end

      it "should make the query method return true" do
        @thing.photo?.should be_true
      end

      it "should return stored file attributes" do
        @thing.photo_file_name.should == "test.jpg"
      end

      it "should return the path to the file for all styles" do
        @thing.photo.path(:original).should == "#{temporary_directory}/#{@thing.id}.original.jpg"
        @thing.photo.path(:small).should == "#{temporary_directory}/#{@thing.id}.small.jpg"
      end

      it "should not appear changed" do
        @thing.photo.changed?.should be_false
      end
    end
  end

  describe "#set" do
    configure_attachment do |spec|
      path "#{spec.temporary_directory}/:id.:style.jpg"
      style :small, {}
      store_file_attributes :file_name
    end

    describe "when no attachment was present" do
      before do
        @thing = Thing.create(:photo => nil)
        @thing.should_not be_new_record
      end

      describe "when a new file is assigned" do
        before do
          @thing.photo = uploaded_file('test2.jpg', '.')
        end

        it "should make the query method return true" do
          @thing.photo?.should be_true
        end

        it "should set the file attributes" do
          @thing.photo_file_name.should == "test2.jpg"
        end

        it "should return the path to the new file for all styles" do
          @thing.photo.path(:original).should == "#{temporary_directory}/#{@thing.id}.original.jpg"
          @thing.photo.path(:small).should == "#{temporary_directory}/#{@thing.id}.small.jpg"
        end

        it "should appear changed" do
          @thing.photo.changed?.should be_true
        end
      end

      describe "when nil is assigned" do
        before do
          @thing.photo = nil
        end

        it "should make the query method return false" do
          @thing.photo?.should be_false
        end

        it "should clear the file attributes" do
          @thing.photo_file_name.should be_nil
        end

        it "should return nil for the path of all styles" do
          @thing.photo.path(:original).should be_nil
          @thing.photo.path(:small).should be_nil
        end

        it "should not appear changed" do
          @thing.photo.changed?.should be_false
        end
      end
    end

    describe "when an attachment was present" do
      before do
        @thing = Thing.create(:photo => uploaded_file('test.jpg', '...'))
        @thing.should_not be_new_record
      end

      describe "when a new file is assigned" do
        before do
          @thing.photo = uploaded_file('test2.jpg', '.')
        end

        it "should make the query method return true" do
          @thing.photo?.should be_true
        end

        it "should set the file attributes" do
          @thing.photo_file_name.should == "test2.jpg"
        end

        it "should return the path to the new file for all styles" do
          @thing.photo.path(:original).should == "#{temporary_directory}/#{@thing.id}.original.jpg"
          @thing.photo.path(:small).should == "#{temporary_directory}/#{@thing.id}.small.jpg"
        end

        it "should appear changed" do
          @thing.photo.changed?.should be_true
        end
      end

      describe "when nil is assigned" do
        before do
          @thing.photo = nil
        end

        it "should make the query method return false" do
          @thing.photo?.should be_false
        end

        it "should clear the file attributes" do
          @thing.photo_file_name.should be_nil
        end

        it "should return nil for the path of all styles" do
          @thing.photo.path(:original).should be_nil
          @thing.photo.path(:small).should be_nil
        end

        it "should appear changed" do
          @thing.photo.changed?.should be_true
        end
      end
    end
  end

  describe "when the record is saved" do
    configure_attachment do |spec|
      path "#{spec.temporary_directory}/:id.:style.jpg"
      style :small, {}
      store_file_attributes :file_name
    end

    describe "when the attachment was created" do
      before do
        @file = uploaded_file('test.jpg', '...')
        @thing.photo = @file
      end

      it "should create the original file" do
        @thing.save.should be_true
        File.exist?(original_path).should be_true
        File.read(original_path).should == "..."
      end

      it "should not create any processed files" do
        @thing.save.should be_true
        File.exist?(small_path).should be_false
      end
    end

    describe "when the attachment was updated" do
      before do
        @thing.update_attributes(:photo => uploaded_file('test.jpg', '...')).should be_true
        @thing = Thing.find(@thing.id)
        @file = uploaded_file('test2.jpg', '.')
        @thing.photo = @file
      end

      it "should update the original file" do
        File.exist?(original_path).should be_true
        File.read(original_path).should == '...'
        @thing.save.should be_true
        File.exist?(original_path).should be_true
        File.read(original_path).should == '.'
      end

      it "should delete any existing processed files" do
        @thing.save.should be_true
        File.exist?(small_path).should be_false
      end
    end

    describe "when the attachment was deleted" do
      before do
        @thing.update_attributes(:photo => uploaded_file('test.jpg', '...')).should be_true
        write_file(small_path, '...')
        @thing = Thing.find(@thing.id)
        @thing.photo = nil
      end

      it "should delete the original file" do
        File.exist?(original_path).should be_true
        @thing.save.should be_true
        File.exist?(original_path).should be_false
      end

      it "should delete any existing processed files" do
        File.exist?(small_path).should be_true
        @thing.save.should be_true
        File.exist?(small_path).should be_false
      end
    end

    describe "when the attachment was never assigned" do
      before do
        @thing.photo = uploaded_file('test.jpg', '...')
        @thing.save.should be_true
        @thing = Thing.find(@thing.id)

        File.exist?(original_path).should be_true
        @original_mtime = set_mtime(original_path, 1.minute.ago)
        File.exist?(small_path).should be_false
        write_file(small_path, '.')
        @small_mtime = set_mtime(small_path, 1.minute.ago)
      end

      it "should leave the original file untouched" do
        File.exist?(original_path).should be_true
        File.mtime(original_path).should == @original_mtime
      end

      it "should leave any processed files untouched" do
        File.exist?(small_path).should be_true
        File.mtime(small_path).should == @small_mtime
      end
    end

    describe "when the value was set from nil to nil" do
      before do
        @thing.update_attributes(:photo => nil).should be_true
        @thing = Thing.find(@thing.id)
        @thing.photo = nil
      end

      it "should not create the original file" do
        File.exist?(original_path).should be_false
        @thing.save.should be_true
        File.exist?(original_path).should be_false
      end

      it "should not create any processed files" do
        File.exist?(small_path).should be_false
        @thing.save.should be_true
        File.exist?(small_path).should be_false
      end
    end

    describe "when the value was set from one file to another" do
      before do
        @thing.photo = uploaded_file('test.jpg', 'old')
        @thing.save.should be_true

        # TODO: Replace this with a call to #process_attachment.  Need
        # to not stub out system calls so the imagemagick call works,
        # or else stub out #process_attachment to just write the file.
        FileUtils.cp(original_path, small_path)

        @thing = Thing.find(@thing.id)

        File.exist?(original_path).should be_true
        File.exist?(small_path).should be_true
        @small_mtime = set_mtime(small_path, 1.minute.ago)
        @original_mtime = set_mtime(original_path, 1.minute.ago)
        @thing.photo = uploaded_file('test.jpg', 'new')
      end

      it "should update the original file" do
        @thing.save.should be_true
        File.mtime(original_path).should_not == @original_mtime
      end

      it "should not update the processed file" do
        @thing.save.should be_true
        File.mtime(small_path).should == @small_mtime
      end
    end

    describe "when a small uploaded file was set" do
      before do
        @thing.photo = small_uploaded_file('test.jpg', 'content')
      end

      it "should create the original file successfully" do
        @thing.save.should be_true
        File.read(original_path).should == 'content'
      end
    end

    describe "when a large uploaded file was set" do
      before do
        @thing.photo = large_uploaded_file('test.jpg', 'content')
      end

      it "should create the original file successfully" do
        @thing.save.should be_true
        File.read(original_path).should == 'content'
      end
    end
  end

  describe "when the record is destroyed" do
    configure_attachment do |spec|
      path "#{spec.temporary_directory}/:id.:style.jpg"
      style :small, {:size => '10x10'}
      store_file_attributes :file_name
    end

    before do
      @thing.photo = large_uploaded_file('test.jpg', 'content')
      @thing.save.should be_true
      write_file(original_path, '...')
      File.exist?(original_path).should be_true
    end

    describe "before the attachment has been processed" do
      it "should delete the original file" do
        @thing.destroy.should be_true
        File.exist?(original_path).should be_false
      end
    end

    describe "when the attachment has been processed" do
      before do
        write_file(small_path, '...')
        File.exist?(small_path).should be_true
      end

      it "should delete the original file" do
        @thing.destroy.should be_true
        File.exist?(original_path).should be_false
      end

      it "should delete any processed files" do
        @thing.destroy.should be_true
        File.exist?(small_path).should be_false
      end
    end
  end
end

describe "Attribute which stores file attributes" do
  describe "assigning to an attachment" do
    set_up_model_class :Thing do |t|
      t.string :photo_file_name
      t.string :photo_content_type
      t.integer :photo_file_size
      t.datetime :photo_updated_at
    end

    before do
      Thing.has_attachment :photo do
        type :base
      end
      Thing.attachment_reflections[:photo].stubs(:file_attributes).returns(
        :file_name => :photo_file_name,
        :content_type => :photo_content_type,
        :file_size => :photo_file_size,
        :updated_at => :photo_updated_at
      )
    end

    describe "when the value is a small uploaded file (StringIO)" do
      it "should set the file attributes" do
        file = small_uploaded_file('test.jpg', '...')
        file.should be_a(StringIO)  # sanity check
        thing = Thing.new(:photo => file)
        thing.photo_file_name.should == 'test.jpg'
        thing.photo_content_type.should == 'image/jpeg'
        thing.photo_file_size.should == 3
        thing.photo_updated_at.should == Time.now
      end
    end

    describe "when the value is a large uploaded file (Tempfile)" do
      it "should set the file attributes" do
        file = large_uploaded_file('test.jpg', '...')
        file.should be_a(Tempfile)  # sanity check
        thing = Thing.new(:photo => file)
        thing.photo_file_name.should == 'test.jpg'
        thing.photo_content_type.should == 'image/jpeg'
        thing.photo_file_size.should == 3
        thing.photo_updated_at.should == Time.now
      end
    end

    describe "when the value is nil" do
      it "should clear the file attributes" do
        file = uploaded_file('test.jpg', '...')
        thing = Thing.new(:photo => file)
        # sanity checks
        thing.photo_file_name.should_not be_nil
        thing.photo_content_type.should_not be_nil
        thing.photo_file_size.should_not be_nil
        thing.photo_updated_at.should_not be_nil

        warp_ahead 1.second

        thing.photo = nil
        thing.photo_file_name.should be_nil
        thing.photo_content_type.should be_nil
        thing.photo_file_size.should be_nil
        thing.photo_updated_at.should == Time.now
      end
    end
  end
end
