require 'tempfile'

module Bulldog
  if RUBY_VERSION >= '1.8.7'
    Tempfile = ::Tempfile
  else
    #
    # Backport Ruby 1.8.7's Tempfile feature which allows specifying the
    # extension by passing in the path as a 2-element array.  Useful for
    # things like ImageMagick, which often rely on the file extension.
    #
    class Tempfile < ::Tempfile
      private

      def make_tmpname(basename, n)
        case basename
        when Array
          prefix, suffix = *basename
        else
          prefix, suffix = basename, ''
        end

        t = Time.now.strftime("%Y%m%d")
        path = "#{prefix}#{t}-#{$$}-#{rand(0x100000000).to_s(36)}-#{n}#{suffix}"
      end
    end
  end
end
