# desc "Explaining what the task does"
# task :d_solr do
#   # Task goes here
# end

desc "Reindex all task"
task :solr_reindex_all => [ :environment ] do
  #DSolr.reindex_all
  DSolr.reindex("Inst")
  DSolr.reindex("Coll")
  DSolr.reindex("GenericObject")
end

desc "Fix OCR data"
task :fix_ocr_data => [ :environment ] do
  PdfFile.all.each do |obj|
    if obj.generic_object.present?
      puts "ID is: " + obj.id.to_s
      if obj.generic_object.identifier.present?
        ia_id = obj.generic_object.identifier.split('/').last
        djvu_data_text_response = fetch("http://archive.org/download/#{ia_id}/#{ia_id}_djvu.txt")

        obj.ocr = djvu_data_text_response.body.squish if djvu_data_text_response.body.present?
        obj.original_ocr = djvu_data_text_response.body if djvu_data_text_response.body.present?
      else
        obj.ocr = obj.pdf_ocr(obj.content)
        obj.original_ocr = obj.pdf_ocr_original(obj.content)
      end

      obj.save!
    end
  end

  DocumentFile.all.each do |obj|
    obj.ocr = obj.pdf_ocr(File.open("#{obj.full_directory}/#{obj.sha256}.pdf", "rb").read)
    obj.original_ocr = obj.pdf_ocr_original(File.open("#{obj.full_directory}/#{obj.sha256}.pdf", "rb").read)
  end
end

desc "Add initial Hist versions"
task :add_initial_versions => [ :environment ] do
  GenericObject.all.each do |obj|
    obj.record_version(user: obj.depositor)
  end
end
