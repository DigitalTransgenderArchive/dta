class Inst < ActiveRecord::Base
  include CommonSolrAssignments

  before_destroy :remove_from_solr
  after_initialize :mint
  after_save :send_solr

  include ::InstObjectAssignments

  has_many :generic_objects

  has_many :inst_image_files
  belongs_to :geonames, optional: true

  has_many :inst_colls, dependent: :destroy
  has_many :colls, :through=>:inst_colls

  def title
    self.name
  end

  def title=(value)
    self.name = value
  end

  def around_save
    do_member_reindex = self.title_changed? || self.colls_ids_changed?
    yield #saves
    reindex_members if do_member_reindex
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

  def solr_model_name
    "Institution"
  end

  def destroy
    if self.colls.present? || self.generic_objects.present?
      raise 'Cannot Delete an Institution with Collections or Objects associated to it.'
    end

    super
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

=begin
    if self.lng.present? and self.lat.present?
      geojson_hash_base = {type: 'Feature', geometry: {type: 'Point'}}
      geojson_hash_base[:geometry][:coordinates] = [self.lng,self.lat]
      geojson_hash_base[:properties] = {placename: self.name}

      doc[:inst_geojson_hash_ssi] = geojson_hash_base.to_json
      doc[:inst_coordinates_geospatial] = ["#{self.lat},#{self.lng}"]
    end
=end

    doc
  end

end
