class GenericObjectsController < ApplicationController
  include Blacklight::Catalog
  include DtaSearchHelper
  include DtaStaticBuilder

  copy_blacklight_config_from(CatalogController)

  before_action :get_latest_content

  before_action :verify_contributor, except: [:show, :citation] #FIXME: Added show for now... but need to remove that...

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
    @generic_file.views = @generic_file.views + 1
    @generic_file.save!
    if @generic_file.visibility == "hidden" and !current_or_guest_user.contributor?
      redirect_to root_path
    else
      search_term = current_search_session.present? ? current_search_session.query_params["q"].to_s : 'N/A: Directly Linked'
      session[:search_term] = search_term

      unless current_user.present? and current_user.is_contributor?
        ahoy.track_visit
        ahoy.track "Object View", {title: @generic_file.title}, {collection_pid: @generic_file.coll.pid, institution_pid: @generic_file.inst.pid, pid: params[:id], model: "GenericObject", search_term: search_term}
      end

      respond_to do |format|
        format.html do
          setup_next_and_previous_documents
          @show_response, @document = fetch(params[:id])
        end
      end
    end
  end

  def new
    @generic_object = GenericObject.new

    if session[:unsaved_generic_object].present?
      begin
        @generic_object.update(ActiveSupport::HashWithIndifferentAccess.new(session[:unsaved_generic_object]))
      rescue => ex
      end
      session[:unsaved_generic_object] = nil
    end

    @selectable_collection = []

    institutions = Inst.all.pluck(:name, :pid)
    @selectable_institution = institutions.sort_by { |key, val| key }
  end

  def create
    if params.key?(:upload_type) and params[:upload_type] == 'single'
      unless validate_metadata(params, 'create')
        session[:unsaved_generic_object] = params[:generic_object]
        #redirect_to new_generic_object_path
        redirect_back(fallback_location: new_generic_object_path)
      else

      @generic_object = GenericObject.find_or_initialize_by(pid: params[:pid])
      form_fields = params['generic_object']

      @generic_object.title = form_fields[:title]
      @generic_object.alt_titles = form_fields[:alt_titles] if form_fields[:alt_titles][0].present?
      @generic_object.creators = form_fields[:creators] if form_fields[:creators][0].present?
      @generic_object.contributors = form_fields[:contributors] if form_fields[:contributors][0].present?
      @generic_object.date_created = form_fields[:date_created] if form_fields[:date_created][0].present?
      @generic_object.date_issued = form_fields[:date_issued] if form_fields[:date_issued][0].present?
      @generic_object.temporal_coverage = form_fields[:temporal_coverage] if form_fields[:temporal_coverage][0].present?

      form_fields[:lcsh_subjects].each_with_index do |s, index|
        if s.present?
          form_fields[:lcsh_subjects][index] = s.split('(').last
          form_fields[:lcsh_subjects][index].gsub!(/\)$/, '')
        end
      end
      form_fields[:geonames].each_with_index do |s, index|
        if s.present?
          form_fields[:geonames][index] = s.split('(').last
          form_fields[:geonames][index].gsub!(/\)$/, '')
        end
      end
      form_fields[:homosaurus_subjects].each_with_index do |s, index|
        if s.present?
          form_fields[:homosaurus_subjects][index] = s.split('(').last
          form_fields[:homosaurus_subjects][index].gsub!(/\)$/, '')
        end
      end
      @generic_object.geonames = form_fields[:geonames] if form_fields[:geonames][0].present?
      @generic_object.homosaurus_subjects = form_fields[:homosaurus_subjects] if form_fields[:homosaurus_subjects][0].present?
      @generic_object.lcsh_subjects = form_fields[:lcsh_subjects] if form_fields[:lcsh_subjects][0].present?
      @generic_object.other_subjects = form_fields[:other_subjects] if form_fields[:other_subjects][0].present?

      @generic_object.flagged = form_fields[:flagged]
      @generic_object.analog_format = form_fields[:analog_format] if form_fields[:analog_format][0].present?
      @generic_object.digital_format = form_fields[:digital_format] if form_fields[:digital_format][0].present?

      @generic_object.descriptions = form_fields[:descriptions] if form_fields[:descriptions][0].present?
      @generic_object.toc = form_fields[:toc] if form_fields[:toc][0].present?
      @generic_object.languages = form_fields[:languages] if form_fields[:languages][0].present?

      @generic_object.publishers = form_fields[:publishers] if form_fields[:publishers][0].present?
      @generic_object.related_urls = form_fields[:related_urls] if form_fields[:related_urls][0].present?
      @generic_object.rights = form_fields[:rights] if form_fields[:rights][0].present?
      @generic_object.rights_free_text = form_fields[:rights_free_text] if form_fields[:rights_free_text][0].present?
      @generic_object.depositor = current_user.to_s

      @generic_object.is_shown_at = form_fields[:is_shown_at] if form_fields[:is_shown_at][0].present?
      @generic_object.hosted_elsewhere = form_fields[:hosted_elsewhere]

      @generic_object.inst = Inst.find_by(pid: params[:institution])
      @generic_object.coll = Coll.find_by(pid: params[:collection])

      @generic_object.visibility = "private"

      if params[:generic_object][:hosted_elsewhere] != "0"
        if params.key?(:filedata)
          file = params[:filedata]

          image = MiniMagick::Image.open(file.path())

          if File.extname(file.original_filename) == '.pdf'
            image.format('jpg', 0, {density: '300'})
          else
            image.format "jpg"
          end

          image.resize "500,600"

          @generic_object.add_file(image.to_blob, 'image/jpeg', File.basename(file.original_filename,File.extname(file.original_filename)))
        end
      else
        file = params[:filedata]
        @generic_object.add_file(File.open(file.path(), 'rb').read, file.content_type, file.original_filename)
      end

      @generic_object.save!

     ProcessFileWorker.perform_async(@generic_object.base_files[0].id)
      redirect_to generic_object_path(@generic_object.pid), notice: "This object has been created."
      end

    end
  end

  def swap_visibility
    if @generic_object.visibility == "public"
      @generic_object.visibility = "private"
    else
      @generic_object.visibility = "public"
    end
    @generic_object.save!
  end

  def destroy
    GenericObject.find_by(pid: params[:id]).destroy!
    redirect_to root_path, notice: "This object has been removed from the system."
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
    if !params.key?(:filedata) && params[:generic_object][:hosted_elsewhere] != "1" && type != 'update'
      flash[:error] = 'No file was uploaded!'

      return false
    end

    params[:generic_object][:date_created].each do |date_created|
      if date_created.present? and Date.edtf(date_created).nil?
        flash[:error] = 'Incorrect format for date created. Please check the EDTF guidelines.'
        return false
      end
    end

    params[:generic_object][:date_issued].each do |date_issued|
      if date_issued.present? and Date.edtf(date_issued).nil?
        flash[:error] = 'Incorrect format for date issued. Please check the EDTF guidelines.'
        return false
      end
    end

    params[:generic_object][:temporal_coverage].each do |temporal_coverage|
      if temporal_coverage.present? and Date.edtf(temporal_coverage).nil?
        flash[:error] = 'Incorrect format for temporal coverage. Please check the EDTF guidelines.'
        return false
      end
    end

    params[:generic_object][:languages].each do |language|
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
