class ImageFile < BaseFile
  def create_derivatives
    derivative = self.start_derivative

    image = MiniMagick::Image.open(self.full_path)
    image.format "jpg"
    image.resize '338x493'
    derivative.mime_type = 'image/jpeg'
    derivative.content = image.to_blob
    derivative.save!
  end
end
