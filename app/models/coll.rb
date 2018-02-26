class Coll < ActiveRecord::Base
  include CommonSolrAssignments
  before_destroy :remove_from_solr
  after_initialize :mint
  after_save :send_solr

  has_many :generic_objects
  belongs_to :generic_object, optional: true

  has_many :inst_colls, dependent: :destroy
  has_many :insts, :through=>:inst_colls

  def around_save
    do_member_reindex = self.title_changed? || self.inst_id_changed?
    yield #saves
    reindex_members if do_member_reindex
  end

  def reindex_members
    self.generic_objects.each do |obj|
      obj.send_solr
    end
  end

  def mint
    self.pid = Pid.mint if self.pid.nil?
  end

  def solr_model_name
    "Collection"
  end

  def delete
    self.destroy
  end

  def generate_solr_content(doc={})
    doc = solr_common_content(doc)

    doc[:depositor_ssim] = [self.depositor]
    doc[:depository_tesim] = doc[:depositor_ssim]
    doc[:title_tesim] = [self.title]
    doc[:collection_name_unique_tesim] = doc[:title_tesim]
    doc[:collection_name_ssim] = doc[:title_tesim]
    doc[:description_tesim] = [self.description]
    doc[:hasCollectionMember_ssim] = self.generic_objects.pluck(:pid)
    doc[:isMemberOfCollection_ssim] = self.insts.pluck(:pid)
    doc[:title_primary_ssi] = self.title
    doc[:title_primary_ssort] = self.title.gsub(/^The /, '').gsub(/^A /, '').gsub(/^An /, '')
    doc[:institution_name_ssim] = self.insts.pluck(:name)
    doc[:institution_pid_ssi] = self.insts.first.pid if self.insts.present?
    doc[:institution_pid_ssim] = self.insts.pluck(:id)
    doc[:thumbnail_ident_ss] = self.generic_object.pid if self.generic_object.present?

    doc
  end
end
