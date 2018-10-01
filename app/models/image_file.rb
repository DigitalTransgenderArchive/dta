class ImageFile < BaseFile
  def create_derivatives
    derivative = self.start_derivative

    image = MiniMagick::Image.open(self.full_path)
    image.format "jpg"
    image.resize '338x493'
    derivative.mime_type = 'image/jpeg'
    derivative.content = image.to_blob
    derivative.save!

    preview = self.start_preview

    image = MiniMagick::Image.open(self.full_path)
    image.format "jpg"
    image.resize '850x1000>'
    preview.mime_type = 'image/jpeg'
    preview.content = image.to_blob
    preview.save!

    if self.generic_object.hosted_elsewhere == "0"
      carousel = self.start_carousel

      image = MiniMagick::Image.open(self.full_path)

      if self.generic_object.pid == 'n296wz15f'
        image.format "jpg"
        image.resize '1920x2330^'

        image.combine_options do |c|
          c.gravity "South"
          c.extent "1920x1920"
        end
      else
        image.format "jpg"
        image.resize '1920x1920^'

        image.combine_options do |c|
          c.gravity "Center"
          c.extent "1920x1920"
        end
      end

      carousel.mime_type = 'image/jpeg'
      carousel.content = image.to_blob
      carousel.save!
    end


  end
end
