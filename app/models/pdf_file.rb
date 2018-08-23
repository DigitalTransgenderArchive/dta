class PdfFile < BaseFile
  def create_derivatives
    derivative = self.start_derivative

    img = MiniMagick::Image.read(self.content)

    img.format('png', 0, {density: 300})

    img.combine_options do |c|
      c.trim "+repage"
      c.background '#FFFFFF'
      c.alpha 'remove'
      #c.flatten
    end

    img.format('jpg', 0, {density: '300'})
    #img.resize '338x493'
    img.resize '338x493'
    derivative.mime_type = 'image/jpeg'
    derivative.content = img.to_blob
    derivative.save!


    preview = self.start_preview
    img = MiniMagick::Image.read(self.content)

    img.format('png', 0, {density: 300})

    img.combine_options do |c|
      c.trim "+repage"
      c.background '#FFFFFF'
      c.alpha 'remove'
      #c.flatten
    end

    img.format('jpg', 0, {density: '300'})
    #img.resize '338x493'
    img.resize '700x1000>'
    preview.mime_type = 'image/jpeg'
    preview.content = img.to_blob
    preview.save!

    preview = self.start_preview
    img = MiniMagick::Image.read(self.content)

    img.format('png', 0, {density: 300})

    img.combine_options do |c|
      c.trim "+repage"
      c.background '#FFFFFF'
      c.alpha 'remove'
      #c.flatten
    end

    img.format('jpg', 0, {density: '300'})
    #img.resize '338x493'
    img.resize '700x1000>'
    preview.mime_type = 'image/jpeg'
    preview.content = img.to_blob
    preview.save!


    carousel = self.start_carousel
    img = MiniMagick::Image.read(self.content)

    img.format('png', 0, {density: 300})

    img.combine_options do |c|
      c.trim "+repage"
      c.background '#FFFFFF'
      c.alpha 'remove'
      #c.flatten
    end

    img.format('jpg', 0, {density: '300'})
    #img.resize '338x493'
    img.resize '1920x1920^'

    img.combine_options do |c|
      c.gravity "North"
      c.extent "1920x1920"
    end

    carousel.mime_type = 'image/jpeg'
    carousel.content = img.to_blob
    carousel.save!


    text_content = ''
    #Internet Archive Object
    if self.generic_object.identifier.present?
      ia_id = self.generic_object.identifier.split('/').last
      djvu_data_text_response = BaseFile.fetch("http://archive.org/download/#{ia_id}/#{ia_id}_djvu.txt")

      self.ocr = djvu_data_text_response.body.squish if djvu_data_text_response.body.present?
      self.original_ocr = djvu_data_text_response.body if djvu_data_text_response.body.present?
    else
      self.ocr = pdf_ocr(self.content)
      self.original_ocr = pdf_ocr_original(self.content)
    end

    self.save!
  end


end
