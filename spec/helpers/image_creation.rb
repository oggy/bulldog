module ImageCreation
  def create_image(path, options={})
    options[:size] ||= '10x10'
    convert = Bulldog::Processor::ImageMagick.convert_path
    system(convert, '-geometry', "#{options[:size]}!", 'pattern:checkerboard', path)
    path
  end
end
