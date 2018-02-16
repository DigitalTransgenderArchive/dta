class GenericFilesController < ApplicationController
  include Blacklight::Catalog
  include DtaSearchHelper
  include DtaStaticBuilder

  copy_blacklight_config_from(CatalogController)

  #before_action :get_latest_content

  #before_action :verify_contributor, except: [:show, :citation] #FIXME: Added show for now... but need to remove that...

  #Needed because it attempts to load from Solr in: load_resource_from_solr of Sufia::FilesControllerBehavior
  #skip_load_and_authorize_resource :only=> [:create, :swap_visibility, :show] #FIXME: Why needed for swap visibility exactly?

  #GenericFilesController.search_params_logic += [:add_access_controls_to_solr_params, :add_advanced_parse_q_to_solr, :exclude_unwanted_models]

  # Blacklight uses #search_action_url to figure out the right URL for
  # the global search box
  def search_action_url options = {}
    search_catalog_url(options.except(:controller, :action))
  end
  helper_method :search_action_url

  # routed to /files/:id
  def show
    #super
    @generic_file = GenericObject.find_by(pid: params[:id])
    if @generic_file.visibility == "hidden" and !current_or_guest_user.contributor?
      redirect_to root_path
    else
      respond_to do |format|
        format.html do
          setup_next_and_previous_documents
          @show_response, @document = fetch(params[:id])
        end
      end
    end
  end

  def new
    super

    if session[:unsaved_generic_file].present?
      begin
        @generic_file.update(ActiveSupport::HashWithIndifferentAccess.new(session[:unsaved_generic_file]))
      rescue => ex
      end
      session[:unsaved_generic_file] = nil
    end

    @form = edit_form

    #@selectable_collection = []
=begin
    @selectable_collection = Collection.all #FIXME
    @selectable_collection = @selectable_collection.sort_by { |collection| collection.title.first }
=end

    #term_query = Collection.find_with_conditions("*:*", rows: '10000', fl: 'id,title_tesim' )
    #term_query = term_query.sort_by { |term| term["title_tesim"].first }
    @selectable_collection = []
    #term_query.each { |term| @selectable_collection << [term["title_tesim"].first, term["id"]] }

    term_query = Institution.find_with_conditions("*:*", rows: '10000', fl: 'id,name_ssim' )
    term_query = term_query.sort_by { |term| term["name_ssim"].first }
    @selectable_institution = []
    term_query.each { |term| @selectable_institution << [term["name_ssim"].first, term["id"]] }

    #@selectable_collection = @selectable_collection
  end

  def create
    if params.key?(:upload_type) and params[:upload_type] == 'internetarchive'
      #result = Resque.enqueue(InternetArchive::DtaBooks, :collection_id=>params[:collection_internet_archive], :institution_id=>params[:institution_internet_archive], :depositor=>current_user.user_key)
      collection_id = 'digitaltransgenderarchive'
      @url = "http://archive.org/advancedsearch.php?q=collection%3A%22#{collection_id}%22&fl%5B%5D=identifier&output=json&rows=10000"
      list_response = Typhoeus::Request.get(@url)
      list_response_as_json = JSON.parse(list_response.body)
      list_response_as_json["response"]["docs"].each do |result|
        result = Resque.enqueue(InternetArchive::DtaSingleBook, :collection_id=>params[:collection_internet_archive], :institution_id=>params[:institution_internet_archive], :depositor=>current_user.user_key, :ia_id=>result['identifier'])
      end
      #InternetArchiveBooks.perform_async(params[:collection_internet_archive], params[:institution_internet_archive], current_user.user_key)
      #redirect_to sufia.dashboard_files_path, notice: render_to_string(partial: 'generic_files/asset_updated_flash', locals: { generic_file: @generic_file })
      flash[:notice] = "Internet archive ingest started in background!"
      redirect_to sufia.dashboard_files_path
    elsif params.key?(:upload_type) and params[:upload_type] == 'harvardbooks'
      @start = 0
      @step = 250
      @end_val = 9999999
      #@url = "http://archive.org/advancedsearch.php?q=collection%3A%22#{collection_id}%22&fl%5B%5D=identifier&output=json&rows=10000"

      while @end_val >= @start do
        @url = "https://api.lib.harvard.edu/v2/items?q=mc614%2520demaios&physicalLocation=Schlesinger&limit=#{@step}&start=#{@start}"

        list_response = Typhoeus::Request.get(@url, ssl_verifypeer: false)
        response_xml = Nokogiri::XML(list_response.body)
        response_xml.remove_namespaces!

        @end_val =  response_xml.xpath("//numFound").text.to_i
        @start = @start + @step

        response_xml.xpath("//mods").each do |record_meta_xml|
          result = Resque.enqueue(Harvard::HarvardSingleBook, :metadata=>record_meta_xml.to_s, :collection_id=>params[:collection_harvard_books], :institution_id=>params[:institution_harvard_books], :depositor=>current_user.user_key)
        end
      end
        flash[:notice] = "Harvard Books ingest started in background!"
        redirect_to sufia.dashboard_files_path
    elsif params.key?(:upload_type) and params[:upload_type] == 'antoniobooks'
      @client = OAI::Client.new "http://digital.utsa.edu/oai/oai.php"
      opts = {}
      opts[:metadata_prefix] = "oai_dc"
      opts[:set] = "p15125coll9"
      response = @client.list_records(opts).full
      response.each_with_index do |result, index|
        result = Resque.enqueue(SanAntonio::SingleObject, :metadata=>result.metadata.to_s, :collection_id=>params[:collection_antonio_books], :institution_id=>params[:institution_antonio_books], :depositor=>current_user.user_key, :record_id=>result.header.identifier)
      end
      flash[:notice] = "San Anontio ingest started in background!"
      redirect_to sufia.dashboard_files_path
    elsif params.key?(:upload_type) and params[:upload_type] == 'wellcome'
        ids = ['b20430838','b20641783','b20641801','b20642982','b20642994','b20643548','b20643603','b2045336x','b20453140','b20453127','b2045322x','b20453255','b20452986','b20453012','b20453024','b20453036','	','b20453115','	','b2045319x','	','b20451787','	','b20451921','	','b20453176','	','b20453188','	','b20453206','b20643536','b20643597','	','b20452962','b20452901','b2045174x','b20451775','b2045286x','b20450709','b20451520','b20451805','b20451945','b20451970','b20451982','b20452007','b20452020','b20452032','b20452044','b20452056','b20452068','b20452081','b20452809','b20453164','b20643007','b20452895','b20452858','b20452925','b20451933','b20451969','b20452949','b20453267','b20438734','b20451994','b20451738','b20594239','b20607507','b20643512','b20451702','b20451842','b20451647','b20451672','b20450928','b20433517','b20451532','b20643482','b20441290','b20450904','b20448843','b20451696','b20429472','b20429496','b20430279','b20430280','b20430449','b20433530','b20434340','b20434352','b20434364','b20434583','b20434662','b20434832','b20434868','b20437791','b20437808','b20438266','b20441228','b20447619','b20449045','b20449409','b20449446','b20449471','b20449604','b20449902','b20449926','b20450187','b20450667','b20450722','b20450746','b20450862','b20450941','b20451362','b20451386','b20451398','b20451404','b2045143x','b20451441','b20451453','b20451507','b20451660','b20607490','b20607519','b20641813','b20642970','b20643020','b20643494','b20643524','b20643573','b20434054','b20450060','b20450886','b20449306','b20449720','b20433426','b20434893','b20449379','b20449392','b20449938','b20450047','b20450059','b20435113','b20438746','b2044977x','b20429502','b20449380','b20434844','b2043487x','b20449768','b20450084','b20450254','b20429484','b20433529','b20434042','b20434248','b20435071','b20435216','b2043778x','b20445581','b20447395','b20432501','b20432781','b20433438','b2043344x','b20433578','b20433803','b20433876','b2043425x','b20434273','b2043439x','b20435022','b20435058','b20435150','b20438874','b20438953','b20438977','b20441423','b20441435','b20448223','b20604968','b20430693','b20430711','b20430759','b20430760','b20430814','b20432719','b20432793','b20432859','b20432914','b20432975','b20433049','b20433268','b20433347','b20433396','b20433487','b20433499','b20434017','b20434261','b20434595','b20434595','b20435034','b20437912','b20438060','b20438072','b20438102','b20438138','b20438308','b20438758','b20438783','b2044087x','b20440923','b20440972','b20441083','b20441113','b20441265','b20441605','b20441903','b20442749','b20442750','b2044297x','b20444692','b2044543x','b20447826','b20448235','b20448466','b20448764','b2044879x','b20449288','b20604981','b20604993','b20605018','b20605031','b20605067','b20605109','b20606011','b20429514','b20433013','b20443171','b20443195','b20447681','b2060497x','b20429447','b20433037','b20435149','b20438795','b20444680','b2043070x','b20430826','b20432513','b20432690','b20433001','b20433025','b20433335','b20437833','b20440881','b20442877','b20442919','b20443109','b20444266','b20444473','b20444679','b20444874','b20448478','b2044848x','b2044980x','b20434170','b20444722','b20444928','b20447577','b20447590','b20447851','b20447863','b20447875','b20448028','b2044803x','b20448776','b20385286','b20430553','b20430802','b20432598','b2043280x','b20433773','b20434649','b2043781x','b20437882','b20438023','b20438813','b20438849','b20438850','b20438862','b20441022','b20441782','b20442865','b20442890','b20443031','b20444254','b20445040','b20448089','b20430528','b20430565','b2043084x','b20432434','b20432628','b20432823','b20432951','b20433505','b20433591','b20433736','b20433840','b20433864','b2043389x','b20434030','b2043408x','b20434443','b20434819','b20438278','b20438837','b20440984','b20444977','b20444989','b20445015','b20445489','b20605262','b20433694','b20433827','b20433888','b20434066','b20448806','b20643585','b2043067x','b20430723','b20430747','b20430887','b20443006','b20445349','b20450205','b20432677','b20429435','b20433050','b20433608','b20437997','b2043800x','b20438011','b20438047','b20441514','b20449136','b20429460','b20430504','b20430772','b20441666','b20441708','b20441721','b20441745','b20434558','b20434558','b20434704','b20434790','b20438163','b20450333','b20433232','b20432641','b20441344','b20441484','b20447723','b20429459','b20434716','b20433372','b20430383','b20430486','b20433281','b20607453','b20607465','b20607477','b20607489','b20433633','b20430450','b20433657','b20433852','b20451799','b20607441','b20433839','b20605213','b20452834','b20445453','b20445490','b20445544','b20448107','b2044901x','b20449422','b2043456x','b20445362','b20445350','b20434224','b20435083','b20447565','b20643470','b20447589','b20448971','b20641795','b20641345','b20438059','b20642325','b20643445','b20643457','b20448168','b20641734','b20430371','b20434212','b20445027','b20643500','b2064355x','b20434522','b20444916','b20448259','b20642957','b20643561','b2044820x','b20444588','b20448491','b20642052','b20643615','b20445052','b20643433','b20642337','b20434091','b20434121','b2043442x','b20448612','b20448041','b20448016','b20438321','b20444795','b20643019','b20445088','b20448053','b20448946','b20449082','b20641333','b20448181','b20433669','b20444436','b20434674','b20445404','b20448600','b20643627','b20445076','b20453383','b20434108','b20447620','b20451659','b2044509x','b20445118','b2044512x','b20448818','b20448831','b20444904','b20641357','b20641369','b20434479','b20453802','b20453887','b20453930','b20453966','b20454053','b20454314','b20454363','b20454557','b20454569','b20454582','b20454594','b20454612','b20454624','b20454636','b20454661','b20454697','b20454703','b20454739','b20453899','b20453905','b20453929','b20453954','b20454016','b20454211','b20454259','b20454508','b2045451x','b20454521','b20453759','b2045370x','b20453735','b20454028','b20453723','b20454648','b20451830','b20643469','b20430681','b20434650']
        ids.each do |id|
          if id.present?
            list_response = Typhoeus::Request.get("https://wellcomelibrary.org/data/#{id}.xml", ssl_verifypeer: false)
            response_xml = Nokogiri::XML(list_response.body)
            response_xml.remove_namespaces!

            result = Resque.enqueue(Wellcome::SingleObject, :metadata=>response_xml.to_s, :collection_id=>params[:collection_wellcome], :institution_id=>params[:institution_wellcome], :depositor=>current_user.user_key, :id=>id)
          end
        end
        flash[:notice] = "Wellcome ingest started in background!"
        redirect_to sufia.dashboard_files_path
    elsif params.key?(:upload_type) and params[:upload_type] == 'single'
      if !validate_metadata(params, 'create')

        if params[:generic_file][:other_subject].present?
          params[:generic_file][:other_subject].collect!{|x| x.strip || x }
          params[:generic_file][:other_subject].reject!{ |x| x.blank? }
        end

        #FIXME: This should be done elsewhere...
        params[:generic_file][:lcsh_subject].each_with_index do |s, index|
          #s.gsub!(/^[^(]+\(/, '')
          if s.present?
            params[:generic_file][:lcsh_subject][index] = s.split('(').last
            params[:generic_file][:lcsh_subject][index].gsub!(/\)$/, '')
          end
        end

        params[:generic_file][:homosaurus_subject].each do |s|
          s.gsub!(/^[^(]+\(/, '')
          #s = s.split('(').last
          s.gsub!(/\)$/, '')
        end

        params[:generic_file][:based_near].each do |s|
          s.gsub!(/^[^(]+\(/, '')
          #s = s.split('(').last
          s.gsub!(/\)$/, '')
        end



        if params[:generic_file][:lcsh_subject].present? and !params[:generic_file][:other_subject].nil?
          params[:generic_file][:other_subject] += params[:generic_file][:lcsh_subject]
          params[:generic_file].delete(:lcsh_subject)
        end

        if params[:generic_file][:homosaurus_subject].present? and !params[:generic_file][:other_subject].nil?
          params[:generic_file][:other_subject] += params[:generic_file][:homosaurus_subject]
          params[:generic_file].delete(:homosaurus_subject)
        end

        if params[:generic_file][:homosaurus_subject].present? and params[:generic_file][:lcsh_subject].present? and params[:generic_file][:other_subject].nil?
          params[:generic_file][:lcsh_subject] += params[:generic_file][:homosaurus_subject]
          params[:generic_file].delete(:homosaurus_subject)
        end
        #END FIXME

        params[:generic_file][:title] = [params[:generic_file][:title]]
        session[:unsaved_generic_file] = params[:generic_file]
        redirect_to sufia.new_generic_file_path
      else
        #Batch.find_or_create(params[:batch_id])
        #Actor sets @generic_file to blank...
        @generic_file = ::GenericFile.new

        @generic_file.title = [params[:generic_file][:title]]
        @generic_file.label = params[:generic_file][:title]

        #actor.create_metadata(params[:batch_id])
        self.add_default_metadata

        if params[:generic_file][:hosted_elsewhere] != "0"
          if params.key?(:filedata)
            file = params[:filedata]
            img = Magick::Image.read(file.path()).first
            img = Magick::Image.from_blob( img.to_blob { self.format = "jpg" } ).first

            if File.extname(file.original_filename) == '.pdf'
              thumb = img.resize_to_fit(500,600) #338,493
            else
              thumb = img.resize_to_fit(500,600) #FIXME?
            end



            self.create_content(StringIO.open(thumb.to_blob), File.basename(file.original_filename,File.extname(file.original_filename)), file_path, 'image/jpeg', params[:collection])
          else
=begin
            saved = actor.save_characterize_and_record_committer
            if saved
              actor.add_file_to_collection(params[:collection])
            end
=end

          end
        else
          file = params[:filedata]
          self.create_content(file, file.original_filename, file_path, file.content_type, params[:collection])
        end


        @generic_file.save!

        acquire_lock_for(@upload_collection_id) do
          collection = ::Collection.find(params[:collection]) if params[:collection].present?
          collection.add_members [@generic_file.id]
          collection.save!
        end

        institution = Institution.find(params[:institution])
        @generic_file.institutions << [institution]

        self.update_metadata

        @generic_file.save!
        @generic_file.record_version_committer(current_user)
        @generic_file.reload
        @generic_file.save!
        Sufia.queue.push(CharacterizeJob.new(@generic_file.id))

        redirect_to sufia.dashboard_files_path, notice: render_to_string(partial: 'generic_files/asset_updated_flash', locals: { generic_file: @generic_file })
      end


    else
      create_from_upload(params)
    end
  end

  def add_default_metadata
    @generic_file.depositor = current_user.user_key
    @generic_file.permissions_attributes = [{ type: 'group', name: 'public', access: 'read' }, {type: 'group', name: 'admin', access: 'edit'}, {type: 'group', name: 'superuser', access: 'edit'}]

    @generic_file.apply_depositor_metadata(current_user)
    time_in_utc = DateTime.now.new_offset(0)
    @generic_file.date_uploaded = time_in_utc
    @generic_file.date_modified = time_in_utc
  end

  def create_content(file, file_name, path, mime_type, collection_id = nil)
    @generic_file.add_file(file, path: path, original_name: file_name, mime_type: mime_type)
    @generic_file.label ||= file_name
    @generic_file.title = [@generic_file.label] if @generic_file.title.blank?
  end


  def validate_metadata(params, type)
    if !params.key?(:filedata) && params[:generic_file][:hosted_elsewhere] != "1" && type != 'update'
      flash[:error] = 'No file was uploaded!'

      return false
    end

    params[:generic_file][:date_created].each do |date_created|
      if date_created.present? and Date.edtf(date_created).nil?
        flash[:error] = 'Incorrect format for date created. Please check the EDTF guidelines.'
        return false
      end
    end

    params[:generic_file][:date_issued].each do |date_issued|
      if date_issued.present? and Date.edtf(date_issued).nil?
        flash[:error] = 'Incorrect format for date issued. Please check the EDTF guidelines.'
        return false
      end
    end

    params[:generic_file][:temporal_coverage].each do |temporal_coverage|
      if temporal_coverage.present? and Date.edtf(temporal_coverage).nil?
        flash[:error] = 'Incorrect format for temporal coverage. Please check the EDTF guidelines.'
        return false
      end
    end

    params[:generic_file][:language].each do |language|
      if language.present? and !language.match(/id\.loc\.gov\/vocabulary\/iso639\-2\/\w\w\w/)
        flash[:error] = 'Language was not selected from the autocomplete?'
        return false
      end
    end
    return true
  end

  def regenerate
    Sufia.queue.push(CharacterizeJob.new(params[:id]))
    flash[:notice] = "Thumbnail scheduled to be regenerated!"
    redirect_to sufia.dashboard_files_path
  end

  def swap_visibility
    #update_visibility
    obj = ActiveFedora::Base.find(params[:id])
    if obj.visibility == 'restricted'
      obj.visibility = 'open'
    else
      obj.visibility = 'restricted'
    end
    obj.save
    flash[:notice] = "Visibility of object was changed!"
    redirect_to request.referrer
  end

  # this is provided so that implementing application can override this behavior and map params to different attributes
  def update_metadata
=begin
    if params[:generic_file][:lcsh_subject].present? and params[:generic_file][:other_subject].present?
      params[:generic_file][:other_subject] += params[:generic_file][:lcsh_subject]
      params[:generic_file].delete(:lcsh_subject)
    end
=end

    params[:generic_file][:lcsh_subject].each_with_index do |s, index|
      #s.gsub!(/^[^(]+\(/, '')
      if s.present?
        params[:generic_file][:lcsh_subject][index] = s.split('(').last
        params[:generic_file][:lcsh_subject][index].gsub!(/\)$/, '')
      end
    end

    params[:generic_file][:homosaurus_subject].each do |s|
      s.gsub!(/^[^(]+\(/, '')
      #s = s.split('(').last
      s.gsub!(/\)$/, '')
    end

    params[:generic_file][:based_near].each do |s|
      s.gsub!(/^[^(]+\(/, '')
      #s = s.split('(').last
      s.gsub!(/\)$/, '')
    end

    if params[:generic_file][:other_subject].present?
      params[:generic_file][:other_subject].collect!{|x| x.strip || x }
      params[:generic_file][:other_subject].reject!{ |x| x.blank? }
    end

    if params[:generic_file][:lcsh_subject].present? and !params[:generic_file][:other_subject].nil?
      params[:generic_file][:other_subject] += params[:generic_file][:lcsh_subject]
      params[:generic_file].delete(:lcsh_subject)
    end

    if params[:generic_file][:homosaurus_subject].present? and !params[:generic_file][:other_subject].nil?
      params[:generic_file][:other_subject] += params[:generic_file][:homosaurus_subject]
      params[:generic_file].delete(:homosaurus_subject)
    end

    if params[:generic_file][:homosaurus_subject].present? and params[:generic_file][:lcsh_subject].present? and params[:generic_file][:other_subject].nil?
      params[:generic_file][:lcsh_subject] += params[:generic_file][:homosaurus_subject]
      params[:generic_file].delete(:homosaurus_subject)
    end

    if params[:generic_file][:title].present?
      params[:generic_file][:title] = [params[:generic_file][:title]]
    end

    if params[:generic_file][:creator].present?
      params[:generic_file][:creator].collect!{|x| x.strip || x }
      params[:generic_file][:creator].reject!{ |x| x.blank? }
    end

    if params[:generic_file][:contributor].present?
      params[:generic_file][:contributor].collect!{|x| x.strip || x }
      params[:generic_file][:contributor].reject!{ |x| x.blank? }
    end

    file_attributes = edit_form_class.model_attributes(params[:generic_file])
    #actor.update_metadata(file_attributes, params[:visibility])
    @generic_file.attributes = file_attributes
    @generic_file.visibility = params[:visibility]
    @generic_file.date_modified = DateTime.now
  end

  def edit
    object = GenericFile.find(params[:id])
    term_query = Institution.find_with_conditions("*:*", rows: '10000', fl: 'id,name_ssim' )
    term_query = term_query.sort_by { |term| term["name_ssim"].first }
    @selectable_institution = []
    term_query.each { |term| @selectable_institution << [term["name_ssim"].first, term["id"]] }

    if object.institutions.present?
      @institution_id = object.institutions.first.id
      term_query = Collection.find_with_conditions("isMemberOfCollection_ssim:#{@institution_id}", rows: '10000', fl: 'id,title_tesim' )
      term_query = term_query.sort_by { |term| term["title_tesim"].first }
      @selectable_collection = []
      term_query.each { |term| @selectable_collection << [term["title_tesim"].first, term["id"]] }
      @collection_id = object.collections.first.id if object.collections.present?
    else
      @selectable_collection = []
    end

    super
  end

  def update
    #FIXME
    if wants_to_upload_new_version? and @generic_file.hosted_elsewhere == "1"
      if params[:filedata]
        file = params[:filedata]
        img = Magick::Image.read(file.path()).first
        img = Magick::Image.from_blob( img.to_blob { self.format = "jpg" } ).first

        if File.extname(file.original_filename) == '.pdf'
          thumb = img.resize_to_fit(500,600) #338,493
        else
          thumb = img.resize_to_fit(500,600) #FIXME?
        end
        @generic_file.add_file(StringIO.open(thumb.to_blob), path: file_path, original_name: File.basename(file.original_filename,File.extname(file.original_filename)), mime_type: 'image/jpeg')
        #actor.save_characterize_and_record_committer
        @generic_file.save!
        @generic_file.record_version_committer(current_user)

        redirect_to sufia.edit_generic_file_path(tab: params[:redirect_tab]), notice:
            render_to_string(partial: 'generic_files/asset_updated_flash', locals: { generic_file: @generic_file })
      end
    elsif params.key? :generic_file and !params[:generic_file][:permissions_attributes]
      if !validate_metadata(params, 'update')
        redirect_to sufia.edit_generic_file_path(:id => @generic_file.id), notice: "An error prevented this item from being updated."
      else

        super
        #@generic_file = GenericFile.find(params[:id])

        @generic_file.institutions.each do |inst|
          @generic_file.institutions.delete(inst)
=begin
          acquire_lock_for(inst.id) do
            inst.reload
            inst.files.delete(@generic_file)
          end
=end
        end

        @generic_file.collections.each do |coll|
          acquire_lock_for(coll.id) do
            coll.reload
            coll.members.delete(@generic_file)
          end
        end

        @generic_file.institutions = []
        @generic_file.collections = []

        #FIXME
        acquire_lock_for(params[:collection]) do
          collection = Collection.find(params[:collection])
          collection.members << [@generic_file]
          collection.save!
        end

        institution = Institution.find(params[:institution])
        @generic_file.institutions << [institution]
        @generic_file.save!

        #This seems like it might be needed... bummer if so... otherwise to_solr doesn't work right it seems
        @generic_file = GenericFile.find(@generic_file.id)
        @generic_file.update_index

=begin
        acquire_lock_for(params[:institution]) do
          institution = Institution.find(params[:institution])
          @generic_file.institutions << [institution]
        end
=end
        
        #@generic_file = GenericFile.find(@generic_file.id)
        #@generic_file.update_index
        #raise params[:institution]
      end
    else
      super
    end




  end


  
end
