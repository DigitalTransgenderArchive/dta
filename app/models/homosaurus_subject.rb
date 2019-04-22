class HomosaurusSubject < ActiveRecord::Base
  before_destroy :remove_from_solr
  #after_save :send_solr

  serialize :alt_labels, Array
  serialize :broader, Array
  serialize :narrower, Array
  serialize :related, Array
  serialize :closeMatch, Array
  serialize :exactMatch, Array

  has_many :object_homosaurus_subject
  has_many :generic_object, :through=>:object_homosaurus_subject

  def model_name
    "Homosaurus"
  end

  def remove_from_solr
    DSolr.delete_by_id "homosaurus/terms/#{self.identifier}"
  end

  def delete
    self.destroy
  end

  def send_solr
    doc = generate_solr_content
    DSolr.put doc
  end

  def generate_solr_content(doc={})
    doc[:id] = "homosaurus/terms/#{self.identifier}"
    doc[:system_create_dtsi] = "#{self.created_at.iso8601}"
    doc[:system_modified_dtsi] = "#{self.updated_at.iso8601}"
    doc[:model_ssi] = self.model_name
    doc[:has_model_ssim] = [self.model_name]
    doc[:date_created_tesim] = [self.created_at.iso8601.split('T')[0]]
    doc[:date_created_ssim] = doc[:date_created_tesim]
    doc[:issued_dtsi] = doc[:system_create_dtsi]
    doc[:modified_dtsi] = doc[:system_modified_dtsi]

    doc[:version_ssi] = self.version

    doc[:prefLabel_ssim] = [self.label]
    doc[:prefLabel_tesim] = doc[:prefLabel_ssim]
    doc[:broader_ssim] = self.broader
    doc[:related_ssim] = self.related
    doc[:narrower_ssim] = self.narrower
    doc[:closeMatch_ssim] = self.closeMatch
    doc[:exactMatch_ssim] = self.exactMatch
    doc[:altLabel_tesim] = self.alt_labels
    doc[:altLabel_ssim] = doc[:altLabel_tesim]
    doc[:identifier_ssi] = self.identifier
    doc[:description_ssi] = self.description
    doc[:description_tesim] = [self.description]

    doc[:dta_homosaurus_lcase_prefLabel_ssi] = self.label.downcase
    doc[:dta_homosaurus_lcase_altLabel_ssim] = []
    self.alt_labels.each do |alt|
      doc[:dta_homosaurus_lcase_altLabel_ssim] << alt.downcase
    end

    @broadest_terms = []
    get_broadest(self.identifier)
    doc[:topConcept_ssim] = @broadest_terms if @broadest_terms.present?
    doc[:new_model_ssi] = 'HomosaurusSubject'
    doc[:active_fedora_model_ssi] = 'Homosaurus'
    doc
  end

  def get_broadest(item)
    if HomosaurusSubject.find_by(identifier: item).broader.blank?
      @broadest_terms << item.split('/').last
    else
      HomosaurusSubject.find_by(identifier: item).broader.each do |current_broader|
        get_broadest(current_broader)
      end
    end
  end
end
