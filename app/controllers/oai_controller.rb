class OaiController < ApplicationController
  ListRecord = Struct.new(:id, :date, :dtarecord, :collections)
  SetRecord = Struct.new(:id, :date, :title, :description)
  ROWS = 100

  def index
    @verb = params.delete(:verb)
    raise("Unsupported verb: #{@verb}") unless @verb == 'ListRecords' || @verb == 'ListSets' || @verb == 'GetRecord'

    @metadata_prefix = params.delete(:metadataPrefix) || 'dta_dc'
    raise("Unsupported metadataPrefix: #{@metadata_prefix}") unless @metadata_prefix == 'dta_dc'

    resumption_token = params.delete(:resumptionToken) || '0'
    raise("Unsupported resumptionToken: #{resumption_token}") unless resumption_token =~ /^\d*$/
    @start = resumption_token.to_i

    identifier = params.delete(:identifier) || ''

    if @verb == 'ListRecords'
      if params[:set].present?
        @recordSet = params.delete(:set)
      end
    end

    unsupported = params.keys - %w(action controller format)
    raise("Unsupported params: #{unsupported}") unless unsupported.empty?

    @response_date = Time.now.strftime('%FT%T')

    if @verb == 'ListRecords'
      self.list_records
    elsif @verb == 'ListSets'
      self.list_sets
    elsif @verb == 'GetRecord'
      if identifier.blank?
        raise("Requested GetRecord but did not provide an identifier parameter.")
      end
      self.get_single_record(identifier)
    end


  end

  def list_records
    if @recordSet.present?
      @records =
          RSolr.connect(url: Settings.solr_url)
              .get('select', params: {
                  'q' => "visibility_ssi:public AND model_ssi:GenericFile AND isPartOf_ssim:#{@recordSet}",
                  #'fl' => 'id,timestamp,xml',
                  'rows' => ROWS,
                  'start' => @start
              })['response']['docs'].map do |d|
            ListRecord.new(
                d['id'],
                d['system_modified_dtsi'],
                #PBCore.new(d['xml'])
                GenericObject.find_by(pid: d['id']),
                d['collection_name_ssim']
            )
          end
    else
      @records =
          RSolr.connect(url: Settings.solr_url)
              .get('select', params: {
                  'q' => 'visibility_ssi:public AND model_ssi:GenericFile',
                  #'fl' => 'id,timestamp,xml',
                  'rows' => ROWS,
                  'start' => @start
              })['response']['docs'].map do |d|
            ListRecord.new(
                d['id'],
                d['system_modified_dtsi'],
                #PBCore.new(d['xml'])
                GenericObject.find_by(pid: d['id']),
                d['collection_name_ssim']
            )
          end
    end


    # Not ideal: they'll need to go past the end.
    @next_resumption_token = @start + ROWS unless @records.empty? || @records.length < 100

    respond_to do |format|
      format.xml do
        render :template => "oai/list_records"
      end
    end
  end

  def list_sets
    @records =
        RSolr.connect(url: Settings.solr_url)
            .get('select', params: {
                'q' => 'visibility_ssi:public AND model_ssi:Collection',
                #'fl' => 'id,timestamp,xml',
                'rows' => 500,
                'start' => @start
            })['response']['docs'].map do |d|
          SetRecord.new(
              d['id'],
              d['timestamp'],
              d['title_tesim'][0],
              d['description_tesim'].join('<br /><br />')
          )
        end

    # Not ideal: they'll need to go past the end.
    @next_resumption_token = @start + ROWS unless @records.empty? || @records.length < 100

    respond_to do |format|
      format.xml do
        render :template => "oai/list_sets"
      end
    end
  end

  def get_single_record pid
    @records =
        RSolr.connect(url: Settings.solr_url)
            .get('select', params: {
                'q' => 'visibility_ssi:public AND model_ssi:GenericFile AND id:' + pid,
                #'fl' => 'id,timestamp,xml',
                'rows' => ROWS,
                'start' => @start
            })['response']['docs'].map do |d|
          ListRecord.new(
              d['id'],
              d['timestamp'],
              #PBCore.new(d['xml'])
              GenericObject.find_by(pid: d['id']),
              d['collection_name_ssim']
          )
        end

    # Not ideal: they'll need to go past the end.
    @next_resumption_token = @start + ROWS unless @records.empty? || @records.length < 100

    respond_to do |format|
      format.xml do
        render :template => "oai/get_record"
      end
    end
  end
end
