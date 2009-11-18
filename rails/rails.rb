#
# Helper library for rails/init.rb.
#
module Bulldog
  module Rails
    class << self
      def init(config_path, rails)
        config = read_config(config_path, rails.env)
        set_logger(config, rails.logger)
        set_attribute config, :default_path_template
        set_attribute config, :default_url_template
        set_attribute config, :convert_path
        set_attribute config, :identify_path
        set_attribute config, :ffmpeg_path
        define_interpolations(rails)
      end

      def read_config(path, environment)
        File.exist?(path) or
          return {}
        YAML.load_file(path)[environment]
      end

      def set_logger(config, default_logger)
        case (log_path = config['log_path'])
        when false
          Bulldog.logger = nil
        when nil
          Bulldog.logger = default_logger
        else
          Bulldog.logger = Logger.new(log_path)
        end
      end

      def set_attribute(config, name)
        value = config[name.to_s] and
          Bulldog.send("#{name}=", value)
      end

      def define_interpolations(rails)
        Bulldog.to_interpolate(:rails_root){rails.root}
        Bulldog.to_interpolate(:rails_env){rails.env}
        Bulldog.to_interpolate(:public_path){rails.public_path}
      end
    end
  end
end
