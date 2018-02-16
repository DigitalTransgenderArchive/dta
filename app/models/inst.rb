class Inst < ActiveRecord::Base
  include CommonSolrAssignments

  before_destroy :remove_from_solr
  after_initialize :mint
  #after_save :send_solr

  include ::InstObjectAssignments

  has_many :generic_objects

  has_many :inst_image_files
  belongs_to :geonames, optional: true

  has_many :inst_colls, dependent: :destroy
  has_many :colls, :through=>:inst_colls

  def around_save
    do_member_reindex = self.title_changed? || self.colls_ids_changed?
    yield #saves
    #reindex_members if do_member_reindex
  end

  def reindex_members
    self.colls.each do |obj|
      obj.send_solr
      obj.reindex_members
    end
  end

  def mint
    self.pid = Pid.mint if self.pid.nil?
  end

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
    doc[:has_image_ssi] = self.inst_image_files.present?.to_s
    doc
  end

end
