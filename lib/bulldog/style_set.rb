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

    def slice(*names)
      styles = names.map{|name| self[name]}
      StyleSet[*styles]
    end
  end
end
