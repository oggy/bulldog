module TemporaryDirectory
  def self.included(mod)
    mod.before{init_temporary_directory}
    mod.after{remove_temporary_directory}
  end

  def temporary_directory
    "#{ROOT}/spec/tmp"
  end

  private  # ---------------------------------------------------------

  def init_temporary_directory
    remove_temporary_directory
    FileUtils.mkdir_p(temporary_directory)
  end

  def remove_temporary_directory
    FileUtils.rm_rf(temporary_directory)
  end
end
