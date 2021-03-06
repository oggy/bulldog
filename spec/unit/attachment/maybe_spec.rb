require 'spec_helper'

describe Attachment::Maybe do
  use_model_class(:Thing,
                  :photo_file_name => :string,
                  :photo_file_size => :integer,
                  :photo_content_type => :string)

  before do
    spec = self
    Thing.has_attachment :photo do
      path "#{spec.temporary_directory}/photo.:style.:extension"
    end
  end

  def configure_attachment(&block)
    spec = self
    Thing.has_attachment :photo do
      instance_exec(spec, &block)
    end
    @thing = Thing.new
  end

  describe "#interpolate_path" do
    describe "when the path template is a Symbol" do
      before do
        Thing.class_eval do
          has_attachment :photo do
            path :test_path
          end

          define_method :test_path do |@name, @style|
            "#{name}-#{style.name}"
          end

          attr_reader :name, :style
        end
        @thing = Thing.new
      end

      it "should call the specified method with the attachment name and style" do
        @thing.photo.interpolate_path(:original).should == "photo-original"
        @thing.name == :photo
        @thing.style.name == :original
      end
    end

    describe "when the path template is a String" do
      it "should return the path that the given style name would be stored at" do
        spec = self
        configure_attachment do
          path "#{spec.temporary_directory}/:attachment.:style.jpg"
        end
        @thing.photo.interpolate_path(:original).should == "#{temporary_directory}/photo.original.jpg"
      end

      it "should use the given interpolation parameters" do
        spec = self
        configure_attachment do
          path "#{spec.temporary_directory}/:attachment.:style.jpg"
        end
        @thing.photo.interpolate_path(:original, :style => 'STYLE').should == "#{temporary_directory}/photo.STYLE.jpg"
      end

      it "should use the style's format attribute for the extension by default" do
        spec = self
        configure_attachment do
          style :processed, :format => 'png'
          path "#{spec.temporary_directory}/:attachment.:style.:extension"
        end
        @thing.photo.interpolate_path(:processed, :format => 'png').should == "#{temporary_directory}/photo.processed.png"
      end

      describe "for the original style" do
        it "should support the :basename interpolation key if the basename is given" do
          spec = self
          configure_attachment do
            path "#{spec.temporary_directory}/:attachment.:style/:basename"
          end
          @thing.photo.interpolate_path(:original, :basename => 'file.xyz').should == "#{temporary_directory}/photo.original/file.xyz"
        end

        it "should support the :extension interpolation key if the basename is given" do
          spec = self
          configure_attachment do
            path "#{spec.temporary_directory}/:attachment.:style.:extension"
          end
          @thing.photo.interpolate_path(:original, :basename => 'file.xyz').should == "#{temporary_directory}/photo.original.xyz"
        end

        it "should support the :extension interpolation key if the extension is given" do
          spec = self
          configure_attachment do
            path "#{spec.temporary_directory}/:attachment.:style.:extension"
          end
          @thing.photo.interpolate_path(:original, :extension => 'xyz').should == "#{temporary_directory}/photo.original.xyz"
        end
      end
    end
  end

  describe "#interpolate_url" do
    describe "when the url template is a Symbol" do
      before do
        Thing.class_eval do
          has_attachment :photo do
            url :test_url
          end

          define_method :test_url do |@name, @style|
            "#{name}-#{style.name}"
          end

          attr_reader :name, :style
        end
        @thing = Thing.new
      end

      it "should call the specified method with the attachment name and style" do
        @thing.photo.interpolate_url(:original).should == "photo-original"
        @thing.name == :photo
        @thing.style.name == :original
      end
    end

    describe "when the url template is a String" do
      it "should return the url that the given style name would be found at" do
        spec = self
        configure_attachment do
          url "/:attachment.:style.jpg"
        end
        @thing.photo.interpolate_url(:original).should == "/photo.original.jpg"
      end

      it "should use the given interpolation parameters" do
        spec = self
        configure_attachment do
          url "/:attachment.:style.jpg"
        end
        @thing.photo.interpolate_url(:original, :style => 'STYLE').should == "/photo.STYLE.jpg"
      end

      it "should use the style's format attribute for the extension by default" do
        spec = self
        configure_attachment do
          style :processed, :format => 'png'
          url "/:attachment.:style.:extension"
        end
        @thing.photo.interpolate_url(:processed).should == "/photo.processed.png"
      end

      describe "for the original style" do
        it "should support the :basename interpolation key if the basename is given" do
          spec = self
          configure_attachment do
            url "/:attachment.:style/:basename"
          end
          @thing.photo.interpolate_url(:original, :basename => 'file.xyz').should == "/photo.original/file.xyz"
        end

        it "should support the :extension interpolation key if the basename is given" do
          spec = self
          configure_attachment do
            url "/:attachment.:style.:extension"
          end
          @thing.photo.interpolate_url(:original, :basename => 'file.xyz').should == "/photo.original.xyz"
        end

        it "should support the :extension interpolation key if the extension is given" do
          spec = self
          configure_attachment do
            url "/:attachment.:style.:extension"
          end
          @thing.photo.interpolate_url(:original, :extension => 'xyz').should == "/photo.original.xyz"
        end
      end
    end
  end

  describe "#reload" do
    before do
      @thing = Thing.create!(:photo => uploaded_file('test.png'))
      FileUtils.cp("#{ROOT}/spec/data/test.jpg", @thing.photo.path(:original))
      @thing.photo.reload
    end

    it "should update the file size stored attribute from the file"
    it "should reload the content type stored attribute from the file"
  end
end
