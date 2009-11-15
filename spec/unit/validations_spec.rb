require 'spec_helper'

describe Validations do
  use_model_class(:Thing, :photo_file_name => :string)

  before do
    Thing.has_attachment :photo
  end

  describe "an ActiveRecord validation", :shared => true do
    # Includers must define:
    #   - validation
    #   - make_thing_pass
    #   - make_thing_fail
    describe "when :on => :create is given" do
      before do
        Thing.send validation, :photo, validation_options.merge(:on => :create)
        @thing = Thing.new
      end

      it "should run the validation when creating the record" do
        make_thing_fail
        @thing.should_not be_valid
      end

      it "should not run the validation when updating the record" do
        make_thing_pass
        @thing.save.should be_true  # sanity check

        make_thing_fail
        @thing.should be_valid
      end
    end

    describe "when :on => :update is given" do
      before do
        Thing.send validation, :photo, validation_options.merge(:on => :update)
        @thing = Thing.new
      end

      it "should not run the validation when creating the record" do
        make_thing_fail
        @thing.should be_valid
      end

      it "should run the validation when updating the record" do
        make_thing_pass
        @thing.save.should be_true  # sanity check

        make_thing_fail
        @thing.should_not be_valid
      end
    end

    describe "when :on => :save is given" do
      before do
        Thing.send validation, :photo, validation_options.merge(:on => :save)
        @thing = Thing.new
      end

      it "should run the validation when creating the record" do
        make_thing_fail
        @thing.should_not be_valid
      end

      it "should run the validation when updating the record" do
        make_thing_pass
        @thing.save.should be_true  # sanity check

        make_thing_fail
        @thing.should_not be_valid
      end
    end

    describe "when an :if option is given" do
      before do
        this = self
        Thing.class_eval do
          attr_accessor :flag
          send this.validation, :photo, this.validation_options.merge(:if => :flag)
        end
        @thing = Thing.new
        make_thing_fail
      end

      it "should run the validation if the condition is true" do
        @thing.flag = true
        @thing.should_not be_valid
      end

      it "should not run the validation if the condition is false" do
        @thing.flag = false
        @thing.should be_valid
      end
    end

    describe "when an :unless option is given" do
      before do
        this = self
        Thing.class_eval do
          attr_accessor :flag
          send this.validation, :photo, this.validation_options.merge(:unless => :flag)
        end
        @thing = Thing.new
        make_thing_fail
      end

      it "should not run the validation if the condition is true" do
        @thing.flag = true
        @thing.should be_valid
      end

      it "should run the validation if the condition is false" do
        @thing.flag = false
        @thing.should_not be_valid
      end
    end

    describe "when a :message option is given with a string" do
      before do
        Thing.send validation, :photo, validation_options.merge(:message => 'Bugger.')
        @thing = Thing.new
      end

      it "should use a string given as a :message option as the error message" do
        make_thing_fail
        @thing.valid?.should be_false
        @thing.errors[:photo].should == 'Bugger.'
      end
    end

    def self.it_should_use_i18n_key(key, validation_options={}, &block)
      describe "when the value is #{key.to_s.humanize.downcase}" do
        use_model_class(:Subthing => :Thing)

        before do
          I18n.default_locale = :en
          Thing.send validation, :photo, validation_options
          @thing = Subthing.new
          instance_eval(&block)
        end

        def define_translation(path, value)
          hash = path.split(/\./).reverse.inject(value){|hash, key| {key => hash}}
          path = "#{temporary_directory}/translations.yml"
          open(path, 'w'){|f| f.write(hash.to_yaml)}
          begin
            I18n.backend.load_translations(path)
          ensure
            File.unlink(path)
          end
        end

        it "should use the activerecord.errors.models.CLASS.attributes.ATTRIBUTE.#{key} translation if available" do
          define_translation "en.activerecord.errors.models.subthing.attributes.photo.#{key}", "ERROR"
          @thing.valid?.should be_false
          @thing.errors[:photo].should == 'ERROR'
        end

        it "should fallback to activerecord.errors.models.CLASS.#{key} translation if available" do
          define_translation "en.activerecord.errors.models.subthing.#{key}", "ERROR"
          @thing.valid?.should be_false
          @thing.errors[:photo].should == 'ERROR'
        end

        it "should fallback to the activerecord.errors.models.SUPERCLASS.attributes.ATTRIBUTE.#{key} if available" do
          define_translation "en.activerecord.errors.models.thing.attributes.photo.#{key}", "ERROR"
          @thing.valid?.should be_false
          @thing.errors[:photo].should == 'ERROR'
        end

        it "should fallback to the activerecord.errors.models.SUPERCLASS.#{key} translation if available" do
          define_translation "en.activerecord.errors.models.thing.#{key}", "ERROR"
          @thing.valid?.should be_false
          @thing.errors[:photo].should == 'ERROR'
        end

        it "should fallback to activerecord.errors.messages.#{key} translation if available" do
          define_translation "en.activerecord.errors.messages.#{key}", "ERROR"
          @thing.valid?.should be_false
          @thing.errors[:photo].should == 'ERROR'
        end
      end
    end
  end

  describe ".validates_attachment_presence_of" do
    def validation
      :validates_attachment_presence_of
    end

    def validation_options
      {}
    end

    def make_thing_pass
      @thing.photo = test_image_file
    end

    def make_thing_fail
      @thing.photo = test_empty_file
    end

    it_should_behave_like "an ActiveRecord validation"

    describe "validation" do
      it "should fail if the value is blank" do
        Thing.validates_attachment_presence_of :photo
        @thing = Thing.new(:photo => nil)
        @thing.should_not be_valid
      end

      it "should fail if the file is empty" do
        Thing.validates_attachment_presence_of :photo
        @thing = Thing.new(:photo => test_empty_file)
        @thing.should_not be_valid
      end

      it "should pass if the file is not empty" do
        Thing.validates_attachment_presence_of :photo
        @thing = Thing.new(:photo => test_image_file)
        @thing.should be_valid
      end
    end

    it_should_use_i18n_key(:attachment_blank){@thing.photo = test_empty_file}
  end

  describe ".validates_attachment_file_size_of" do
    def validation
      :validates_attachment_file_size_of
    end

    def validation_options
      {:in => 3..5}
    end

    def make_thing_pass
      @thing.photo = uploaded_file_with_content('test.jpg', '....')
    end

    def make_thing_fail
      @thing.photo = uploaded_file_with_content('test.jpg', '..')
    end

    it_should_behave_like "an ActiveRecord validation"

    describe "validation" do
      it "should not fail if the attachment is blank" do
        Thing.validates_attachment_file_size_of :photo, :greater_than => 5
        thing = Thing.new
        thing.should be_valid
      end

      describe "when :greater_than is given" do
        before do
          Thing.validates_attachment_file_size_of :photo, :greater_than => 5
          @thing = Thing.new
        end

        it "should fail if the file size is less than the limit" do
          @thing.photo = uploaded_file_with_content('test.jpg', '.'*4)
          @thing.should_not be_valid
        end

        it "should fail if the file size is equal to the limit" do
          @thing.photo = uploaded_file_with_content('test.jpg', '.'*5)
          @thing.should_not be_valid
        end

        it "should pass if the file size is greater than the limit" do
          @thing.photo = uploaded_file_with_content('test.jpg', '.'*6)
          @thing.should be_valid
        end
      end

      describe "when :less_than is given" do
        before do
          Thing.validates_attachment_file_size_of :photo, :less_than => 5
          @thing = Thing.new
        end

        it "should fail if the file size is greater than the limit" do
          @thing.photo = uploaded_file_with_content('test.jpg', '.'*6)
          @thing.should_not be_valid
        end

        it "should fail if the file size is equal to the limit" do
          @thing.photo = uploaded_file_with_content('test.jpg', '.'*5)
          @thing.should_not be_valid
        end

        it "should pass if the file size is less than the limit" do
          @thing.photo = uploaded_file_with_content('test.jpg', '.'*4)
          @thing.should be_valid
        end
      end

      describe "when :in is given" do
        before do
          Thing.validates_attachment_file_size_of :photo, :in => 3..5
          @thing = Thing.new
        end

        it "should fail if the file size is less than the lower bound" do
          @thing.photo = uploaded_file_with_content('test.jpg', '.'*2)
          @thing.should_not be_valid
        end

        it "should pass if the file size is equal to the lower bound" do
          @thing.photo = uploaded_file_with_content('test.jpg', '.'*3)
          @thing.should be_valid
        end

        it "should fail if the file size is greater than the upper bound" do
          @thing.photo = uploaded_file_with_content('test.jpg', '.'*6)
          @thing.should_not be_valid
        end
      end

      describe "when :in is given with an inclusive range" do
        before do
          Thing.validates_attachment_file_size_of :photo, :in => 3..5
          @thing = Thing.new
        end

        it "should pass if the file size is equal to the upper bound" do
          @thing.photo = uploaded_file_with_content('test.jpg', '.'*5)
          @thing.should be_valid
        end
      end

      describe "when :in is given with an exclusive range" do
        before do
          Thing.validates_attachment_file_size_of :photo, :in => 3...5
          @thing = Thing.new
        end

        it "should fail if the file size is equal to the upper bound" do
          @thing.photo = uploaded_file_with_content('test.jpg', '.'*5)
          @thing.should_not be_valid
        end
      end
    end

    it_should_use_i18n_key(:attachment_too_large, :in => 3..5){@thing.photo = uploaded_file_with_content('test.jpg', '......')}
    it_should_use_i18n_key(:attachment_too_large, :less_than => 5){@thing.photo = uploaded_file_with_content('test.jpg', '......')}
    it_should_use_i18n_key(:attachment_too_small, :in => 3..5){@thing.photo = uploaded_file_with_content('test.jpg', '..')}
    it_should_use_i18n_key(:attachment_too_small, :greater_than => 5){@thing.photo = uploaded_file_with_content('test.jpg', '..')}
  end

  describe ".validates_attachment_type_of" do
    def validation
      :validates_attachment_type_of
    end

    def validation_options
      {:matches => /\Aimage/}
    end

    def make_thing_pass
      @thing.photo = uploaded_file_with_content('test.jpg', "\xff\xd8")
    end

    def make_thing_fail
      @thing.photo = uploaded_file_with_content('test.avi', "RIFF    AVI ")
    end

    it_should_behave_like "an ActiveRecord validation"

    describe "validation" do
      describe "when :matches is given" do
        before do
          Thing.validates_attachment_type_of :photo, :matches => /^image/
          @thing = Thing.new(:photo => uploaded_file)
        end

        it "should pass if the attachment is nil" do
          @thing.photo = nil
          @thing.should be_valid
        end

        it "should pass if the content type matches the given pattern" do
          @thing.photo.stubs(:content_type).returns('image/jpeg')
          @thing.should be_valid
        end

        it "should fail if the content type does not match the given pattern" do
          @thing.photo.stubs(:content_type).returns('video/x-msvideo')
          @thing.should_not be_valid
          @thing.errors.on(:photo).should_not be_blank
        end
      end

      describe "when :is is given" do
        describe "when the value is a symbol" do
          before do
            Thing.validates_attachment_type_of :photo, :is => :image
            @thing = Thing.new(:photo => uploaded_file)
          end

          it "should pass if the symbol matches the Attachment type" do
            @thing.photo = uploaded_file_with_content('test.jpg', "\xff\xd8")
            @thing.should be_valid
          end

          it "should fail if the symbol does not match the Attachment type" do
            @thing.photo = uploaded_file_with_content('test.avi', "RIFF    AVI ")
            @thing.should_not be_valid
            @thing.errors.on(:photo).should_not be_blank
          end
        end

        describe "when a mime-type string is given" do
          before do
            @thing = Thing.new(:photo => uploaded_file)
          end

          describe "when the string contains optional parameters" do
            before do
              Thing.validates_attachment_type_of :photo, :is => 'image/jpeg; a=1, b=2'
            end

            it "should fail if the type is different" do
              @thing.photo.stubs(:content_type).returns('other/jpeg; a=1, b=2')
              @thing.should_not be_valid
              @thing.errors.on(:photo).should_not be_blank
            end

            it "should fail if the subtype is different" do
              @thing.photo.stubs(:content_type).returns('image/png; a=1, b=2')
              @thing.should_not be_valid
              @thing.errors.on(:photo).should_not be_blank
            end

            it "should fail if a parameter is missing from the attachment" do
              @thing.photo.stubs(:content_type).returns('image/jpeg; a=1')
              @thing.should_not be_valid
              @thing.errors.on(:photo).should_not be_blank
            end

            it "should pass if the type, subtype, and parameters are the same" do
              @thing.photo.stubs(:content_type).returns('image/jpeg; a=1, b=2')
              @thing.should be_valid
            end

            it "should pass if the attachment has additional parameters" do
              @thing.photo.stubs(:content_type).returns('image/jpeg; a=1, b=2, c=3')
              @thing.should be_valid
            end

            it "should pass if the attachment has the same parameters in a different order" do
              @thing.photo.stubs(:content_type).returns('image/jpeg; b=2, a=1')
              @thing.should be_valid
            end
          end

          describe "when the string does not contain optional parameters" do
            before do
              Thing.validates_attachment_type_of :photo, :is => 'image/jpeg'
            end

            it "should fail if the type is different" do
              @thing.photo.stubs(:content_type).returns('other/jpeg')
              @thing.should_not be_valid
              @thing.errors.on(:photo).should_not be_blank
            end

            it "should fail if the subtype is different" do
              @thing.photo.stubs(:content_type).returns('image/png')
              @thing.should_not be_valid
              @thing.errors.on(:photo).should_not be_blank
            end

            it "should pass if the type and subtype are the same" do
              @thing.photo.stubs(:content_type).returns('image/jpeg')
              @thing.should be_valid
            end

            it "should pass if the type and subtype are the same, and the attachment has optional parameters" do
              @thing.photo.stubs(:content_type).returns('image/jpeg; a=1')
              @thing.should be_valid
            end
          end
        end
      end
    end

    it_should_use_i18n_key(:attachment_wrong_type, :matches => /\Aimage/){@thing.photo = uploaded_file_with_content('test.avi', "RIFF    AVI ")}
  end
end
