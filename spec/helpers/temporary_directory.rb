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

    # When an attachment is deleted, it deletes empty ancestral
    # directories.  Don't delete past the temporary directory.
    FileUtils.touch "#{temporary_directory}/.do_not_delete"
  end

  def remove_temporary_directory
    FileUtils.rm_rf(temporary_directory)
  end
end
