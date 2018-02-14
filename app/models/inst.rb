class Inst < ActiveRecord::Base
  include CommonSolrAssignments

  before_destroy :remove_from_solr
  #after_save :send_solr

  include ::InstObjectAssignments

  has_many :generic_objects

  belongs_to :base_file, optional: true
  belongs_to :geonames, optional: true

  has_many :inst_colls, dependent: :destroy
  has_many :colls, :through=>:inst_colls

  def model_name
    "Institution"
  end

  def delete
    self.destroy
  end

  def generate_solr_content(doc={})
    doc = solr_common_content(doc)
    doc[:name_tesim] = [self.name]
    doc[:name_ssim] = doc[:name_tesim]
    doc[:institution_name_ssim] = doc[:name_tesim]
    doc[:title_primary_ssort] = [self.name.gsub(/^The /, '').gsub(/^A /, '').gsub(/^An /, '')]
    doc[:description_tesim] = [self.description]
    doc[:description_ssim] = doc[:description_tesim]
    doc[:institution_url_tesim] = [self.institution_url]
    doc[:has_image_ssi] = self.base_file.present?.to_s
    doc
  end

end
