module Bulldog
  class StyleSet < Array
    def [](arg)
      if arg.is_a?(Symbol)
        if arg == :original
          Style::ORIGINAL
        else
          find{|style| style.name == arg}
        end
      else
        super
      end
    end
  end
end
