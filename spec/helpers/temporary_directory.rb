module TemporaryDirectory
  def self.included(mod)
    mod.before{init_temporary_directory}
    mod.after{remove_temporary_directory}
  end

  def tmp_dir
    "#{PLUGIN_ROOT}/spec/tmp"
  end

  private  # ---------------------------------------------------------

  def init_temporary_directory
    remove_temporary_directory
    FileUtils.mkdir_p(tmp_dir)
  end

  def remove_temporary_directory
    FileUtils.rm_rf(tmp_dir)
  end
end
