class DocumentFile < BaseFile
  def create_derivatives
    derivative = self.start_derivative

    command = "#{Settings.libreoffice_path} -convert-to pdf:writer_pdf_Export --outdir #{self.full_directory} --headless #{self.full_path}"
    result = system(command)

    img = MiniMagick::Image.read("#{self.full_directory}/#{self.sha256}.pdf")

    img.combine_options do |c|
      c.trim "+repage"
    end
    image.format('jpg', 0, {density: '300'})
    img.resize '338x493'
    derivative.mime_type = 'image/jpeg'
    derivative.content = img.to_blob
    derivative.save!



    self.ocr = pdf_ocr(File.open("#{self.full_directory}/#{self.sha256}.pdf", "rb").read)
    self.original_ocr = pdf_ocr_original(File.open("#{self.full_directory}/#{self.sha256}.pdf", "rb").read)

    self.save!
  end
end
