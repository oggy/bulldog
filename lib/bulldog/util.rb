module Bulldog
  module Util
    #
    # Run the given command, logging everything obsessively.
    #
    # Return the output if the command is successful, nil otherwise.
    # If an :expect_status option is given, any status codes in the
    # list are considered successful.
    #
    def run(*command)
      options = command.last.is_a?(Hash) ? command.pop : {}
      command.map!{|x| x.to_s}
      command = Shellwords.join(command) + ' 2>&1'
      Bulldog.logger.info("[Bulldog] Running: #{command}") if Bulldog.logger
      output = `#{command}`
      status = $?.exitstatus
      if Bulldog.logger
        Bulldog.logger.info("[Bulldog] Output: #{output}")
        Bulldog.logger.info("[Bulldog] Status: #{status}")
      end
      expected_statuses = options[:expect_status] || [0]
      expected_statuses.include?(status) ? output : nil
    end

    # Backport Shellwords.join from ruby 1.8.7.
    require 'shellwords'
    if ::Shellwords.respond_to?(:join)
      # ruby >= 1.8.7
      Shellwords = ::Shellwords
    else
      module Shellwords
        #
        # Escapes a string so that it can be safely used in a Bourne shell
        # command line.
        #
        # Note that a resulted string should be used unquoted and is not
        # intended for use in double quotes nor in single quotes.
        #
        #   open("| grep #{Shellwords.escape(pattern)} file") { |pipe|
        #     # ...
        #   }
        #
        def escape(str)
          # An empty argument will be skipped, so return empty quotes.
          return "''" if str.empty?

          str = str.dup

          # Process as a single byte sequence because not all shell
          # implementations are multibyte aware.
          str.gsub!(/([^A-Za-z0-9_\-.,:\/@\n])/n, "\\\\\\1")

          # A LF cannot be escaped with a backslash because a backslash + LF
          # combo is regarded as line continuation and simply ignored.
          str.gsub!(/\n/, "'\n'")

          return str
        end

        module_function :escape

        #
        # Builds a command line string from an argument list +array+ joining
        # all elements escaped for Bourne shell and separated by a space.
        #
        #   open('|' + Shellwords.join(['grep', pattern, *files])) { |pipe|
        #     # ...
        #   }
        #
        def join(array)
          array.map { |arg| escape(arg) }.join(' ')
        end

        module_function :join
      end
    end
  end
end
