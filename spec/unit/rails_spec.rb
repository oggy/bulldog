require 'spec_helper'
require "#{ROOT}/rails/rails"

describe Rails do
  describe "#init" do
    def config_path
      "#{temporary_directory}/config.yml"
    end

    def make_config(attributes)
      config = {'ENVIRONMENT' => attributes}
      open(config_path, 'w') do |file|
        file.puts config.to_yaml
      end
    end

    def init
      fake_rails = OpenStruct.new(
        :env => 'ENVIRONMENT',
        :logger => Logger.new('/dev/null'),
        :root => 'ROOT',
        :public_path => 'PUBLIC'
      )
      Rails.init(config_path, fake_rails)
    end

    it "should set the default path template from the configuration file, if present" do
      make_config('default_path_template' => 'DEFAULT PATH TEMPLATE')
      init
      Bulldog.default_path_template.should == 'DEFAULT PATH TEMPLATE'
    end

    it "should set the default url template from the configuration file, if present" do
      make_config('default_url_template' => 'DEFAULT URL TEMPLATE')
      init
      Bulldog.default_url_template.should == 'DEFAULT URL TEMPLATE'
    end

    it "should set the ffmpeg path from the configuration file, if present" do
      make_config('ffmpeg_path' => 'FFMPEG')
      init
      Bulldog.ffmpeg_path.should == 'FFMPEG'
    end

    it "should set the convert path from the configuration file, if present" do
      make_config('convert_path' => 'CONVERT')
      init
      Bulldog.convert_path.should == 'CONVERT'
    end

    it "should set the identify path from the configuration file, if present" do
      make_config('identify_path' => 'IDENTIFY')
      init
      Bulldog.identify_path.should == 'IDENTIFY'
    end

    it "should not set anything if the configuration file does not exist" do
      default_default_path_template = Bulldog.default_path_template
      init
      Bulldog.default_path_template.should == default_default_path_template
    end

    describe "interpolations" do
      def interpolate(template)
        Interpolation.interpolate(template, @thing, :photo, Style.new(:style))
      end

      it "should interpolate :rails_root as Rails.root" do
        init
        interpolate("a/:rails_root/b").should == "a/ROOT/b"
      end

      it "should interpolate :rails_env as Rails.env" do
        init
        interpolate("a/:rails_env/b").should == "a/ENVIRONMENT/b"
      end

      it "should interpolate :public_path as Rails.public_path" do
        init
        interpolate("a/:public_path/b").should == "a/PUBLIC/b"
      end
    end
  end
end
