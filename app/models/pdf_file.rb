class PdfFile < BaseFile
  def create_derivatives
    derivative = self.start_derivative

    img = MiniMagick::Image.read(self.content)

    img.combine_options do |c|
      c.trim "+repage"
    end
    image.format('jpg', 0, {density: '300'})
    img.resize '338x493'
    derivative.mime_type = 'image/jpeg'
    derivative.content = img.to_blob
    derivative.save!

    text_content = ''
    #Internet Archive Object
    if obj.identifier.present?
      ia_id = obj.identifier[0].split('/').last
      djvu_data_text_response = fetch("http://archive.org/download/#{ia_id}/#{ia_id}_djvu.txt")
      text_content = djvu_data_text_response.body.squish if djvu_data_text_response.body.present?
    else
      text_content = pdf_ocr(self.content)
    end

    self.ocr = text_content
    self.original_ocr = text_content

    self.save!
  end
end
