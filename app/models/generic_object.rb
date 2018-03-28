class GenericObject < ActiveRecord::Base
  include CommonSolrAssignments
  include GenericObjectAssignments
  include GenericObjectSolrAssignments
  has_paper_trail ignore: [:visibility, :views, :downloads, :pid] # on: [:update, :destroy]

  after_save :after_save_actions
  before_destroy :before_destroy_actions
  after_destroy :after_destroy_actions
  after_initialize :mint

  serialize :descriptions, Array
  serialize :temporal_coverage, Array
  serialize :date_issued, Array
  serialize :date_created, Array
  serialize :alt_titles, Array
  serialize :publishers, Array
  serialize :related_urls, Array
  serialize :rights_free_text, Array
  serialize :languages, Array
  # Has the following main tables
  # title - singular
  # datastream - polymorphic
  #

  # Belongs to
  belongs_to :coll
  belongs_to :inst

  # Normal has_many
  has_many :base_files

  # Has Many Through Ones
  has_many :object_genres, dependent: :destroy
  has_many :genres, :through=>:object_genres

  has_many :object_geonames, dependent: :destroy
  has_many :geonames, :through=>:object_geonames

  has_many :object_homosaurus_subjects, dependent: :destroy
  has_many :homosaurus_subjects, :through=>:object_homosaurus_subjects

  has_many :object_lcsh_subjects, dependent: :destroy
  has_many :lcsh_subjects, :through=>:object_lcsh_subjects

  has_many :object_resource_types, dependent: :destroy
  has_many :resource_types, :through=>:object_resource_types

  has_many :object_rights, dependent: :destroy
  has_many :rights, :through=>:object_rights

  # Has Many
  has_many :contributors, dependent: :destroy
  has_many :creators, dependent: :destroy
  has_many :other_subjects, dependent: :destroy

  def after_save_actions
    if !self.id_changed? && (self.views_was != views || self.downloads_was != downloads)
    else
      send_solr
    end
  end

  def before_destroy_actions
    self.remove_from_solr
    @coll = self.coll
    @inst = self.inst
  end

  def after_destroy_actions
    @coll.send_solr
    @inst.send_solr
  end

  def required? key
   ['title', 'creators', 'contributors'].include? key.to_s
  end

  def mint
    self.pid = Pid.mint if self.pid.nil?
  end

  def image?
    return false if self.base_files.empty?
    self.base_files[0].type == 'ImageFile'
  end

  def pdf?
    return false if self.base_files.empty?
    self.base_files[0].type == 'PdfFile'
  end

  def document?
    return false if self.base_files.empty?
    self.base_files[0].type == 'DocumentFile'
  end

  def download_name
    if self.base_files[0].path.present?
      "#{self.title.gsub(/[,;]/, '')}.#{self.base_files[0].path.split('.').last}"
    else
      'No file exists'
    end
  end

  def processing?
    false
  end

  def solr_model_name
    "GenericFile"
  end

  def delete
    self.destroy
  end

  def iiif_id
    if self.base_files.present? and self.base_files[0].path.present?
      path = self.base_files[0].path
      path.gsub!('/', '%2F')
    else
      path = 'doesnotexist'
    end
    path
  end



end
