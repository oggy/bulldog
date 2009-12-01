# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{bulldog}
  s.version = "0.0.10"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["George Ogata"]
  s.date = %q{2009-12-01}
  s.description = %q{= Bulldog

Flexible file attachments for active record.
}
  s.email = %q{george.ogata@gmail.com}
  s.extra_rdoc_files = [
    "LICENSE",
     "README.rdoc"
  ]
  s.files = [
    ".gitignore",
     "CHANGELOG",
     "DESCRIPTION.txt",
     "LICENSE",
     "README.rdoc",
     "Rakefile",
     "VERSION",
     "bulldog.gemspec",
     "lib/bulldog.rb",
     "lib/bulldog/attachment.rb",
     "lib/bulldog/attachment/base.rb",
     "lib/bulldog/attachment/has_dimensions.rb",
     "lib/bulldog/attachment/image.rb",
     "lib/bulldog/attachment/maybe.rb",
     "lib/bulldog/attachment/none.rb",
     "lib/bulldog/attachment/pdf.rb",
     "lib/bulldog/attachment/unknown.rb",
     "lib/bulldog/attachment/video.rb",
     "lib/bulldog/error.rb",
     "lib/bulldog/has_attachment.rb",
     "lib/bulldog/interpolation.rb",
     "lib/bulldog/missing_file.rb",
     "lib/bulldog/processor.rb",
     "lib/bulldog/processor/argument_tree.rb",
     "lib/bulldog/processor/base.rb",
     "lib/bulldog/processor/ffmpeg.rb",
     "lib/bulldog/processor/image_magick.rb",
     "lib/bulldog/processor/one_shot.rb",
     "lib/bulldog/reflection.rb",
     "lib/bulldog/saved_file.rb",
     "lib/bulldog/stream.rb",
     "lib/bulldog/style.rb",
     "lib/bulldog/style_set.rb",
     "lib/bulldog/tempfile.rb",
     "lib/bulldog/util.rb",
     "lib/bulldog/validations.rb",
     "lib/bulldog/vector2.rb",
     "rails/init.rb",
     "rails/rails.rb",
     "script/console",
     "spec/data/empty.txt",
     "spec/data/test.jpg",
     "spec/data/test.mov",
     "spec/data/test.ogg",
     "spec/data/test.pdf",
     "spec/data/test.png",
     "spec/data/test2.jpg",
     "spec/helpers/image_creation.rb",
     "spec/helpers/temporary_directory.rb",
     "spec/helpers/temporary_models.rb",
     "spec/helpers/temporary_values.rb",
     "spec/helpers/test_upload_files.rb",
     "spec/helpers/time_travel.rb",
     "spec/integration/data/test.jpg",
     "spec/integration/lifecycle_hooks_spec.rb",
     "spec/integration/processing_image_attachments.rb",
     "spec/integration/processing_video_attachments_spec.rb",
     "spec/integration/saving_an_attachment_spec.rb",
     "spec/matchers/file_operations.rb",
     "spec/spec_helper.rb",
     "spec/unit/attachment/base_spec.rb",
     "spec/unit/attachment/image_spec.rb",
     "spec/unit/attachment/maybe_spec.rb",
     "spec/unit/attachment/pdf_spec.rb",
     "spec/unit/attachment/video_spec.rb",
     "spec/unit/attachment_spec.rb",
     "spec/unit/has_attachment_spec.rb",
     "spec/unit/interpolation_spec.rb",
     "spec/unit/processor/argument_tree_spec.rb",
     "spec/unit/processor/ffmpeg_spec.rb",
     "spec/unit/processor/image_magick_spec.rb",
     "spec/unit/processor/one_shot_spec.rb",
     "spec/unit/rails_spec.rb",
     "spec/unit/reflection_spec.rb",
     "spec/unit/stream_spec.rb",
     "spec/unit/style_set_spec.rb",
     "spec/unit/style_spec.rb",
     "spec/unit/validations_spec.rb",
     "spec/unit/vector2_spec.rb",
     "tasks/bulldog_tasks.rake"
  ]
  s.homepage = %q{http://github.com/oggy/bulldog}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{A heavy-duty paperclip.  File attachments for ActiveRecord.}
  s.test_files = [
    "spec/helpers/image_creation.rb",
     "spec/helpers/temporary_directory.rb",
     "spec/helpers/temporary_models.rb",
     "spec/helpers/temporary_values.rb",
     "spec/helpers/test_upload_files.rb",
     "spec/helpers/time_travel.rb",
     "spec/integration/lifecycle_hooks_spec.rb",
     "spec/integration/processing_image_attachments.rb",
     "spec/integration/processing_video_attachments_spec.rb",
     "spec/integration/saving_an_attachment_spec.rb",
     "spec/matchers/file_operations.rb",
     "spec/spec_helper.rb",
     "spec/unit/attachment/base_spec.rb",
     "spec/unit/attachment/image_spec.rb",
     "spec/unit/attachment/maybe_spec.rb",
     "spec/unit/attachment/pdf_spec.rb",
     "spec/unit/attachment/video_spec.rb",
     "spec/unit/attachment_spec.rb",
     "spec/unit/has_attachment_spec.rb",
     "spec/unit/interpolation_spec.rb",
     "spec/unit/processor/argument_tree_spec.rb",
     "spec/unit/processor/ffmpeg_spec.rb",
     "spec/unit/processor/image_magick_spec.rb",
     "spec/unit/processor/one_shot_spec.rb",
     "spec/unit/rails_spec.rb",
     "spec/unit/reflection_spec.rb",
     "spec/unit/stream_spec.rb",
     "spec/unit/style_set_spec.rb",
     "spec/unit/style_spec.rb",
     "spec/unit/validations_spec.rb",
     "spec/unit/vector2_spec.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rspec>, [">= 0"])
      s.add_development_dependency(%q<rspec_outlines>, [">= 0"])
      s.add_development_dependency(%q<mocha>, [">= 0"])
    else
      s.add_dependency(%q<rspec>, [">= 0"])
      s.add_dependency(%q<rspec_outlines>, [">= 0"])
      s.add_dependency(%q<mocha>, [">= 0"])
    end
  else
    s.add_dependency(%q<rspec>, [">= 0"])
    s.add_dependency(%q<rspec_outlines>, [">= 0"])
    s.add_dependency(%q<mocha>, [">= 0"])
  end
end

