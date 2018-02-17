module CommonSolrAssignments
  def solr_common_content(doc={})
    doc[:id] = self.pid
    doc[:system_create_dtsi] = "#{self.created_at.iso8601}"
    doc[:system_modified_dtsi] = "#{self.updated_at.iso8601}"
    doc[:date_uploaded_dtsi] = doc[:system_create_dtsi]
    doc[:date_modified_dtsi] = doc[:date_modified_dtsi]
    doc[:model_ssi] = self.solr_model_name
    doc[:has_model_ssim] = [self.solr_model_name]

    doc[:date_created_tesim] = [self.created_at.iso8601.split('T')[0]]
    doc[:date_created_ssim] = doc[:date_created_tesim]
    doc[:visibility_ssi] = self.visibility

    doc
  end

  def send_solr
    doc = generate_solr_content
    DSolr.put doc
  end

  def remove_from_solr
    DSolr.delete_by_id self.pid
  end
end
