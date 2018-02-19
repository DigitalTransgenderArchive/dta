module SolrDocumentBehavior

  ##
  # Give our SolrDocument an ActiveModel::Naming appropriate route_key
  def route_key
    get('has_model_ssim'.split(':')).last.downcase
  end

  def date_uploaded
    field = self['date_uploaded_dtsi']
    return unless field.present?
    begin
      Date.parse(field).to_formatted_s(:standard)
    rescue ArgumentError
      ActiveFedora::Base.logger.info "Unable to parse date: #{field.first.inspect} for #{self['id']}"
    end
  end

  def date_modified
    field = self['date_modified_dtsi']
    return unless field.present?
    begin
      Date.parse(field).to_formatted_s(:standard)
    rescue ArgumentError
      ActiveFedora::Base.logger.info "Unable to parse date: #{field.first.inspect} for #{self['id']}"
    end
  end

  def depositor(default = '')
    val = Array(self['depositor_ssim']).first
    val.present? ? val : default
  end

  def create_date
    Array(self['date_created_ssim']).first
  end

  def model
    self['model_ssi']
  end

  def to_db_model
    self['new_model_ssi'].constantize.find_by(pid: self.id)
  end

  def title
    Array(self['title_tesim']).first
  end

  def description
    Array(self['description_tesim'])
  end

  def collection?
    model == 'Collection'
  end

  def institution?
    model == 'Institution'
  end

  def object?
    model == 'GenericFile'
  end

  def homosaurus?
    model == 'Homosaurus'
  end

  def has_thumbnail?
    self['has_thumbnail_ssi'].present? && self['has_thumbnail_ssi'] == 'true'
  end

  def audio?
    (self['resource_type_tesim'].present? and self['resource_type_tesim'].include?('Audio')) || (self['genre_tesim'].present? and self['genre_tesim'].include?('Sound Recordings'))
  end

  def mime_type
    Array(self["mime_type_tesim"]).first
  end

  def institution
    Array(self['institution_tesim']).first
  end

  def creator
    Array(self['creator_ssim']).join(', ')
  end

  def has_file_content?
    self['has_file_content_ssi'] == 'true'
  end

  # Legacy below this point

  ##
  # Offer the source (ActiveFedora-based) model to Rails for some of the
  # Rails methods (e.g. link_to).
  # @example
  #   link_to '...', SolrDocument(id: 'bXXXXXX5').new => <a href="/dams_object/bXXXXXX5">...</a>
=begin
  def to_model
    @m ||= ActiveFedora::Base.load_instance_from_solr(id)
    return self if @m.class == ActiveFedora::Base
    @m
  end
=end

end
