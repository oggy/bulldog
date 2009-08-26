module FastAttachments
  class StyleSet < Array
    def [](arg)
      if arg.is_a?(Symbol)
        find{|style| style.name == arg}
      else
        super
      end
    end
  end
end
