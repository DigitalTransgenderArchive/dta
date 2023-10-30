class GenericObject < ActiveRecord::Base
  include CommonSolrAssignments
  include GenericObjectAssignments
  include GenericObjectSolrAssignments
  #has_paper_trail ignore: [:visibility, :views, :downloads, :pid] # on: [:update, :destroy]

  include ::Hist::Model
  has_hist associations: {all: {}}

  #after_save :after_save_actions
  #around_save :hist_around_save

  #has_hist associations: [:all] # Broken from through destroy on the join tables...?
  # What happens when an id of a join table is removed?
  #has_hist associations: [:base_files, :genres, :geonames, :homosaurus_subjects, :lcsh_subjects, :resource_types, :rights, :contributors, :creators, :other_subjects]
  #has_hist associations: {all: {}}
  #STEVEN: has_hist associations: [base_files: {}, genres: {}, geonames: {}, homosaurus_subjects: {}, lcsh_subjects: {}, resource_types: {}, rights: {}, contributors: {}, creators: {}, other_subjects: {}]


  #after_save :after_save_actions
  around_save :around_save_actions
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

  has_many :object_homosaurus_v2_subjects, dependent: :destroy
  has_many :homosaurus_v2_subjects, :through=>:object_homosaurus_v2_subjects

  #has_many :object_homosaurus_v3_subjects, dependent: :destroy
  #has_many :homosaurus_v3_subjects, :through=>:object_homosaurus_v3_subjects

  has_many :object_lcsh_subjects, dependent: :destroy
  has_many :lcsh_subjects, :through=>:object_lcsh_subjects

  has_many :object_homosaurus_uri_subjects, dependent: :destroy
  has_many :homosaurus_uri_subjects, :through=>:object_homosaurus_uri_subjects

  has_many :object_resource_types, dependent: :destroy
  has_many :resource_types, :through=>:object_resource_types

  has_many :object_rights, dependent: :destroy
  has_many :rights, :through=>:object_rights

  # Has Many
  has_many :contributors, dependent: :destroy
  has_many :creators, dependent: :destroy
  has_many :other_subjects, dependent: :destroy

  def around_save_actions
    #raise "Huh: " + self.views_was.to_s + " : " + views.to_s + " : " + self.id_changed?.to_s
    self.class.transaction do
      # FIXME: What happens on a version save? How to ensure this was set?
      is_analytics = !self.id_changed? && (self.views_was != views || self.downloads_was != downloads)
      yield

      if !is_analytics
        send_solr
        self.hist_save_actions
        #STEVEN: self.hist_save_actions
      end

    end
  end

=begin
  def after_save_actions
    raise "Huh: " + self.views_was.to_s + " : " + views.to_s + " : " + self.id_changed?.to_s
    if !self.id_changed? && (self.views_was != views || self.downloads_was != downloads)
    else
      send_solr

      self.class.transaction do
        hist_save_actions
      end
    end
  end
=end

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

  def iiif_id(index: 0)
    if self.base_files.present? and self.base_files[index].path.present?
      path = self.base_files[index].path
      path.gsub!('/', '%2F')
    else
      path = 'doesnotexist'
    end
    path
  end

  NS = {
      "xmlns:dc"   => "https://www.digitaltransgenderarchive.net/dc/v1",
      "xmlns:dcterms"   => "https://www.digitaltransgenderarchive.net/dcterms/v1",
  }

  def dta_dc_xml_output
    Nokogiri::XML::Builder.new do |x|
      x['dc'].dta_dc(NS) do
        x.title(self.title)

        self.alt_titles.each do |alt_title|
          x.alternative(alt_title)
        end

        self.descriptions.each do |abstract|
          x.abstract(abstract)
        end

        self.genres.each do |item|
          x.genre(item.label)
        end

        self.resource_types.each do |item|
          x.resource_type(item.label)
        end

        x.format(self.analog_format, type: 'analog') if self.analog_format.present?
        x.format(self.digital_format, type: 'digital') if self.digital_format.present?

        self.date_created.each do |item|
          x.date_created(item)
        end

        self.date_issued.each do |item|
          x.date_issued(item)
        end


        self.temporal_coverage.each do |item|
          x.temporal(item)
        end

        self.lcsh_subjects.each do |item|
          x.subject(item.uri)
        end

        self.homosaurus_uri_subjects.each do |item|
          x.subject(item.uri)
        end

        self.other_subjects.each do |item|
          x.subject(item.label)
        end

        self.geonames.each do |item|
          x.geographic(item.uri)
        end

        self.creators.each do |item|
          x.creator(item.label)
        end

        self.contributors.each do |item|
          x.contributor(item.label)
        end

        self.publishers.each do |item|
          x.publisher(item)
        end

        x.tableOfContents(self.toc) if self.toc.present?

        self.languages.each do |item|
          x.language(item)
        end

        if self.is_shown_at.present?
          x.isShownAt(self.is_shown_at)
        else
          x.isShownAt('https://www.digitaltransgenderarchive.net/files/' + pid)
        end

        if self.base_files.blank? || self.base_files[0].content.blank?
          if self.resource_types.pluck(:label).include?('Audio') || self.genres.pluck(:label).include?('Sound Recordings')
            x.preview("https://www.digitaltransgenderarchive.net" + ActionController::Base.helpers.asset_path("shared/dta_audio_icon.jpg"))
          else
            x.preview("https://www.digitaltransgenderarchive.net" + ActionController::Base.helpers.asset_path("default.png"))
          end
        else
          x.preview("https://www.digitaltransgenderarchive.net/downloads/#{pid}?file=thumbnail")
        end

        self.related_urls.each do |item|
          x.seeAlso(item)
        end

        x.identifier(self.identifier) if self.identifier.present?

        x.rights(self.rights[0].label, type: 'standardized')
        self.rights_free_text.each do |item|
          x.rights(item, type: 'free_text')
        end

        x.flagged(self.flagged) if self.flagged

        x.hosted_elsewhere(self.hosted_elsewhere) if self.hosted_elsewhere

        harvesting_ind = '1'
        x.physicalLocation(inst.name)
        if self.hosted_elsewhere.present? and self.hosted_elsewhere == '1' and not ['Grupo Dignidade ', 'Independent Voices', 'Transas City', 'Cork LGBT Archive', 'JD Doyle Archives'].include?(inst.name)
          harvesting_ind = '0'
        end
        x.aggregatorHarvestingIndicator(harvesting_ind)


      end
    end.to_xml.sub('<?xml version="1.0"?>', '').strip
  end

end
