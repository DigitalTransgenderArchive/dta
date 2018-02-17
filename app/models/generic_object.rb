class GenericObject < ActiveRecord::Base
  include CommonSolrAssignments
  include GenericObjectAssignments
  include GenericObjectSolrAssignments
  has_paper_trail # on: [:update, :destroy]

  #before_destroy :remove_from_solr
  #after_initialize :mint
  #after_save :send_solr

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
    "#{self.title.gsub(/[,;]/, '')}.#{self.base_files[0].path.split('.').last}"
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
    if self.base_files.present?
      path = self.base_files[0].path
      path.gsub!('/', '%2F')
    else
      path = 'doesnotexist'
    end
    path
  end



end
