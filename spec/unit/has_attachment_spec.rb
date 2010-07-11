require 'spec_helper'

describe HasAttachment do
  describe ".has_attachment" do
    use_model_class(:Thing)

    it "should provide accessors for the attachment" do
      Thing.has_attachment :photo
      thing = Thing.new
      thing.photo.should be_a(Attachment::Maybe)
    end

    it "should provide a query method for the attachment" do
      Thing.has_attachment :photo
      thing = Thing.new
      thing.photo?.should be_false
      thing.photo = uploaded_file('test.jpg')
      thing.photo?.should be_true
    end

    it "should configure the existing attachment declared if one exists" do
      Thing.has_attachment :photo do
        style :one
      end
      Thing.has_attachment :photo do
        style :two
      end
      Thing.attachment_reflections[:photo].styles[:one].should_not be_blank
      Thing.attachment_reflections[:photo].styles[:two].should_not be_blank
    end

    describe "when an attachment is inherited" do
      use_model_class(:Parent)

      before do
        # Create the attachment before subclassing
        Parent.has_attachment :photo do
          style :one
        end
      end

      use_model_class(:Child => :Parent)

      it "should not affect the superclasses' attachment" do
        Child.has_attachment :photo do
          style :two
        end
        Child.attachment_reflections[:photo].styles[:two].should_not be_blank
        Parent.attachment_reflections[:photo].styles[:two].should be_blank
      end
    end
  end

  describe ".attachment_reflections" do
    use_model_class(:Thing)

    it "should allow reflection on the field names" do
      Thing.has_attachment :photo
      Thing.attachment_reflections[:photo].name.should == :photo
    end
  end

  describe "#process_attachment" do
    use_model_class(:Thing)

    describe "when there is an attachment set" do
      it "should trigger the configured callbacks" do
        calls = []
        Thing.has_attachment :photo do
          style :normal
          process(:on => :my_event){calls << 1}
        end
        thing = Thing.new(:photo => uploaded_file('test.jpg'))
        thing.process_attachment(:photo, :my_event)
        calls.should == [1]
      end
    end

    describe "when there is no attachment set" do
      it "should not trigger any callbacks" do
        args = nil
        Thing.has_attachment :photo do
          style :normal
          process(:on => :my_event){|*args|}
        end
        thing = Thing.new(:photo => nil)
        thing.process_attachment(:photo, :my_event)
        args.should be_nil
      end
    end

    it "should raise an ArgumentError if the attachment name is invalid" do
      Thing.has_attachment :photo do
        style :normal
        process(:on => :my_event){}
      end
      thing = Thing.new
      lambda do
        thing.process_attachment(:fail, :my_event)
      end.should raise_error(ArgumentError)
    end

    it "should evaluate the callback in the context of the specified processor" do
      with_temporary_constant_value Processor, :Test, Class.new(Processor::Base) do
        context = nil
        Thing.has_attachment :photo do
          style :normal
          process(:on => :my_event, :with => :test){context = self}
        end
        thing = Thing.new(:photo => uploaded_file('test.jpg'))
        thing.process_attachment(:photo, :my_event)
        context.should be_a(Processor::Test)
      end
    end

    it "should default to a base processor instance" do
      context = nil
      Thing.has_attachment :photo do
        style :normal
        process(:on => :my_event){context = self}
      end
      thing = Thing.new(:photo => uploaded_file('test.jpg'))
      thing.process_attachment(:photo, :my_event)
      context.should be_a(Processor::Base)
    end
  end

  describe "object lifecycle" do
    outline "building a record" do
      with_model_class :Thing do
        spec = self

        Thing.has_attachment :attachment do
          detect_type_by{spec.detect_as}
          path "#{spec.temporary_directory}/:style.jpg"
        end

        original_path = "#{temporary_directory}/original.jpg"

        thing = Thing.new(:attachment => eval(value.to_s))
        thing.attachment.should be_a(attachment_class)
      end
    end

    fields :detect_as, :value          , :attachment_class
    values nil       , nil             , Attachment::None
    values :image    , nil             , Attachment::None
    values nil       , :test_image_file, Attachment::Unknown
    values :image    , :test_image_file, Attachment::Image

    outline "loading a record" do
      columns = store_file_name ? {:attachment_file_name => :string} : {}
      with_model_class :Thing, columns do
        spec = self

        Thing.has_attachment :attachment do
          detect_type_by{spec.detect_as}
          path "#{spec.temporary_directory}/:style.jpg"
        end

        original_path = "#{temporary_directory}/original.jpg"

        thing = Thing.create(:attachment => eval(value_saved.to_s))
        if file_exists?
          FileUtils.touch(original_path)
        else
          FileUtils.rm_f(original_path)
        end

        thing = Thing.find(thing.id)
        thing.attachment.should be_a(attachment_class)
        if stream_missing.nil?
          thing.attachment.stream.should be_nil
        else
          thing.attachment.stream.missing?.should == stream_missing
        end
      end
    end

    fields :store_file_name, :detect_as, :value_saved    , :file_exists?, :attachment_class  , :stream_missing
    values false           , nil       , nil             , false        , Attachment::None   , nil
    values false           , nil       , nil             , true         , Attachment::Unknown, false
    values false           , nil       , :test_image_file, false        , Attachment::None   , nil
    values false           , nil       , :test_image_file, true         , Attachment::Unknown, false
    values false           , :image    , nil             , false        , Attachment::None   , nil
    values false           , :image    , nil             , true         , Attachment::Image  , false
    values false           , :image    , :test_image_file, false        , Attachment::None   , nil
    values false           , :image    , :test_image_file, true         , Attachment::Image  , false
    values true            , nil       , nil             , false        , Attachment::None   , nil
    values true            , nil       , nil             , true         , Attachment::None   , nil
    values true            , nil       , :test_image_file, false        , Attachment::Unknown, true
    values true            , nil       , :test_image_file, true         , Attachment::Unknown, false
    values true            , :image    , nil             , false        , Attachment::None   , nil
    values true            , :image    , nil             , true         , Attachment::None   , nil
    values true            , :image    , :test_image_file, false        , Attachment::Image  , true
    values true            , :image    , :test_image_file, true         , Attachment::Image  , false

    describe "when no attributes are stored" do
      use_model_class(:Thing)

      before do
        @file = uploaded_file('test.jpg')
      end

      def configure(&block)
        Thing.attachment_reflections[:photo].configure(&block)
      end

      describe "saving the record" do
        it "should create the original file as long as :basename and :extension are not used" do
          spec = self
          Thing.has_attachment :photo do
            path "#{spec.temporary_directory}/:style.jpg"
          end
          thing = Thing.new(:photo => @file)
          lambda{thing.save}.should create_file("#{temporary_directory}/original.jpg")
        end

        it "should raise an error if :basename is used" do
          spec = self
          Thing.has_attachment :photo do
            path "#{spec.temporary_directory}/:basename"
          end
          thing = Thing.new(:photo => @file)
          lambda{thing.save}.should raise_error(Interpolation::Error)
        end

        it "should raise an error if :extension is used" do
          spec = self
          Thing.has_attachment :photo do
            path "#{spec.temporary_directory}/photo.:extension"
          end
          thing = Thing.new(:photo => @file)
          lambda{thing.save}.should raise_error(Interpolation::Error)
        end

        describe "when the record is reloaded" do
          before do
            spec = self
            Thing.has_attachment :photo do
              path "#{spec.temporary_directory}/:style.jpg"
            end
            @thing = Thing.new(:photo => @file)
            @thing.save
          end

          it "should load the saved original file" do
            @thing.photo.should be_present
            @thing.photo.path.should == "#{temporary_directory}/original.jpg"
          end
        end
      end
    end

    describe "when the file name is stored" do
      use_model_class(:Thing,
                      :photo_file_name => :string,
                      :photo_content_type => :string,
                      :photo_file_size => :integer)

      before do
        spec = self
        Thing.has_attachment :photo do
          path "#{spec.temporary_directory}/photos/:id-:style.:extension"
          style :small, :size => '10x10'
        end
      end

      def configure(&block)
        Thing.attachment_reflections[:photo].configure(&block)
      end

      def original_path
        "#{temporary_directory}/photos/#{@thing.id}-original.jpg"
      end

      def small_path
        "#{temporary_directory}/photos/#{@thing.id}-small.jpg"
      end

      describe "instantiating the record" do
        describe "when the record is new" do
          before do
            @thing = Thing.new
          end

          it "should have no stored attributes set" do
            @thing.photo_file_name.should be_nil
            @thing.photo_content_type.should be_nil
            @thing.photo_file_size.should be_nil
          end
        end

        describe "when the record already exists" do
          describe "when a file name is set, and the original file exists" do
            def instantiate
              file = uploaded_file('test.jpg')
              thing = Thing.create(:photo => file)
              @thing = Thing.find(thing.id)
            end

            it "should have stored attributes set" do
              instantiate
              @thing.photo_file_name.should == 'test.jpg'
              @thing.photo_content_type.split(/;/).first.should == "image/jpeg"
              @thing.photo_file_size.should == File.size(test_path('test.jpg'))
            end
          end

          describe "when the no file name is set, and the original file does not exist" do
            before do
              thing = Thing.create
              @thing = Thing.find(thing.id)
            end

            it "should have no stored attributes set" do
              @thing.photo_file_name.should be_nil
              @thing.photo_content_type.should be_nil
              @thing.photo_file_size.should be_nil
            end
          end

          describe "when a file name is set, but the original file is missing" do
            def instantiate
              file = uploaded_file('test.jpg')
              @thing = Thing.create(:photo => file)
              File.unlink(original_path)
              @thing = Thing.find(@thing.id)
            end

            it "should have stored attributes set" do
              instantiate
              @thing.photo_file_name.should == 'test.jpg'
              @thing.photo_content_type == "image/jpeg"
              @thing.photo_file_size.should == File.size(test_path('test.jpg'))
            end

            describe "when the record is saved" do
              before do
                instantiate
              end

              it "should not create any files" do
                @thing.save
                File.should_not exist(@thing.photo.path(:original))
              end
            end
          end
        end

        describe "when the record exists and there is no attachment" do
          before do
            thing = Thing.create
            @thing = Thing.find(thing.id)
          end

          describe "when an attachment is assigned" do
            before do
              @file = uploaded_file('test.jpg')
            end

            it "should set the stored attributes" do
              @thing.photo = @file
              @thing.photo_file_name.should == 'test.jpg'
              @thing.photo_content_type.split(/;/).first.should == "image/jpeg"
              @thing.photo_file_size.should == File.size(test_path('test.jpg'))
            end

            it "should not create the original file" do
              lambda do
                @thing.photo = @file
              end.should_not create_file(original_path)
            end

            describe "when the record is saved" do
              before do
                @thing.photo = @file
              end

              it "should create the original file" do
                lambda do
                  @thing.save.should be_true
                end.should create_file(original_path)
              end
            end
          end
        end

        describe "when the record exists and there is an attachment" do
          before do
            @old_file = test_file('test.jpg')
            thing = Thing.create(:photo => @old_file)
            @thing = Thing.find(thing.id)
          end

          def old_original_path
            original_path
          end

          def new_original_path
            new_dirname = File.dirname(original_path)
            new_basename = File.basename(original_path, 'jpg') + 'png'
            File.join(new_dirname, new_basename)
          end

          describe "when a new attachment is assigned" do
            before do
              @new_file = test_file('test.png')
            end

            it "should set the stored attributes" do
              @thing.photo = @new_file
              @thing.photo_file_name.should == 'test.png'
              @thing.photo_content_type.split(/;/).first.should == 'image/png'
              @thing.photo_file_size.should == File.size(test_path('test.png'))
            end

            it "should not create the new original file yet" do
              lambda do
                @thing.photo = @new_file
              end.should_not create_file(new_original_path)
            end

            it "should not delete the old original file yet" do
              lambda do
                @thing.photo = @new_file
              end.should_not delete_file(old_original_path)
            end

            describe "when the record is saved" do
              before do
                @thing.photo = @new_file
              end

              it "should create the new original file" do
                lambda do
                  @thing.save.should be_true
                end.should create_file(new_original_path)
              end

              it "should delete the old original file" do
                lambda do
                  @thing.save.should be_true
                end.should delete_file(old_original_path)
              end

              it "should remove any old processed files" do
                FileUtils.touch small_path
                lambda do
                  @thing.save.should be_true
                end.should delete_file(small_path)
              end
            end
          end

          describe "when nil is assigned" do
            it "should not remove the old original file yet" do
              lambda do
                @thing.photo = nil
              end.should_not delete_file(original_path)
            end

            it "should not remove any old processed files yet" do
              FileUtils.touch small_path
              lambda do
                @thing.photo = nil
              end.should_not delete_file(small_path)
            end

            describe "when the record is saved" do
              before do
                @thing.photo = nil
              end

              it "should remove the old original file" do
                lambda do
                  @thing.save
                end.should delete_file(original_path)
              end

              it "should remove any old processed files" do
                FileUtils.touch small_path
                lambda do
                  @thing.save
                end.should delete_file(small_path)
              end

              it "should remove any empty parent directories" do
                lambda do
                  @thing.save
                end.should delete_file("#{temporary_directory}/photos")
              end
            end
          end
        end
      end

      describe "#destroy" do
        describe "when the record is new" do
          before do
            file = uploaded_file('test.jpg')
            @thing = Thing.new(:photo => file)
          end

          it "should not raise an error" do
            lambda{@thing.destroy}.should_not raise_error
          end
        end

        describe "when the record existed but had no attachment" do
          before do
            thing = Thing.create
            @thing = Thing.find(thing.id)
          end

          it "should not raise an error" do
            lambda{@thing.destroy}.should_not raise_error
          end

          it "should not stop the record being destroyed" do
            @thing.destroy
            Thing.exists?(@thing).should be_false
          end
        end

        describe "when the record existed and had an attachment" do
          before do
            file = uploaded_file('test.jpg')
            thing = Thing.create(:photo => file)
            @thing = Thing.find(thing.id)
          end

          it "should not stop the record being destroyed" do
            @thing.destroy
            Thing.exists?(@thing).should be_false
          end

          it "should remove the original file" do
            lambda do
              @thing.destroy
            end.should delete_file(original_path)
          end

          it "should remove any processed files" do
            FileUtils.touch small_path
            lambda do
              @thing.destroy
            end.should delete_file(small_path)
          end

          it "should remove any empty parent directories" do
            lambda do
              @thing.destroy
            end.should delete_file("#{temporary_directory}/photos")
          end
        end
      end
    end
  end

  describe "AR::Dirty" do
    use_model_class(:Thing, :name => :string)

    before do
      spec = self
      Thing.has_attachment :photo do
        path "#{spec.temporary_directory}/:id.jpg"
      end
      thing = Thing.create(:name => 'old', :photo => uploaded_file('test.jpg'))
      @thing = Thing.find(thing.id)
    end

    def original_path
      "#{temporary_directory}/#{@thing.id}.jpg"
    end

    describe "#ATTACHMENT_changed?" do
      it "should return false if nothing has been assigned to the attachment" do
        @thing.photo_changed?.should be_false
      end

      it "should return false if the same value has been assigned to the attachment" do
        @thing.photo = @thing.photo.value
        @thing.photo_changed?.should be_false
      end

      it "should return true if a new value has been assigned to the attachment" do
        @thing.photo = uploaded_file('test.jpg')
        @thing.photo_changed?.should be_true
      end
    end

    describe "#ATTACHMENT_was" do
      it "should return the original value before assignment" do
        original_photo = @thing.photo
        @thing.photo_was.should equal(original_photo)
      end

      it "should return a clone of the original value after assignment" do
        original_photo = @thing.photo
        @thing.photo = uploaded_file('test.jpg')
        @thing.photo_was.should_not equal(original_photo)
        @thing.photo_was.should == original_photo
      end
    end

    describe "#changes" do
      it "should return attachment changes along with other attribute changes" do
        old_photo = @thing.photo
        @thing.name = 'new'
        @thing.photo = uploaded_file('test.jpg')
        @thing.changes.should == {
          'name' => ['old', 'new'],
          'photo' => [old_photo, @thing.photo],
        }
      end
    end

    describe "when the record is saved and only attachments have been modified" do
      before do
        @thing.photo = uploaded_file('test.jpg')
      end

      it "should not hit the database"

      it "should still save the attachment files" do
        lambda do
          @thing.save
        end.should modify_file(original_path)
      end
    end

    describe "#save" do
      before do
        @thing.name = 'new'
        @thing.photo = uploaded_file('test.jpg')
      end

      it "should clear all changes" do
        @thing.save
        @thing.changes.should == {}
      end
    end
  end

  describe "automatic timestamps" do
    describe "#save" do
      use_model_class(:Thing, :photo_updated_at => :datetime)

      before do
        Thing.has_attachment :photo
      end

      describe "when the record is new" do
        before do
          @thing = Thing.new
        end

        describe "when the attachment was not assigned to" do
          it "should not set ATTACHMENT_updated_at" do
            @thing.save.should be_true
            @thing.photo_updated_at.should be_nil
          end
        end

        describe "when nil was assigned to the attachment" do
          it "should not set ATTACHMENT_updated_at" do
            @thing.photo = nil
            @thing.save.should be_true
            @thing.photo_updated_at.should be_nil
          end
        end

        describe "when a file was assigned to the attachment" do
          it "should update ATTACHMENT_updated_at" do
            @thing.photo = uploaded_file('test.jpg')
            @thing.save.should be_true
            @thing.photo_updated_at.should == Time.now
          end
        end
      end

      describe "when the record already exists" do
        before do
          thing = Thing.create(:photo => uploaded_file('test.jpg'))
          @thing = Thing.find(thing.id)
        end

        describe "when the attachment was not assigned to" do
          it "should not update ATTACHMENT_updated_at" do
            warp_ahead 1.minute
            original_updated_at = @thing.photo_updated_at
            @thing.save.should be_true
            @thing.photo_updated_at.should == original_updated_at.drop_subseconds
          end
        end

        describe "when a new file was assigned to the attachment" do
          it "should update ATTACHMENT_updated_at" do
            warp_ahead 1.minute
            @thing.photo = uploaded_file('test.jpg')
            @thing.save.should be_true
            @thing.photo_updated_at.should == Time.now
          end
        end
      end
    end
  end
end
