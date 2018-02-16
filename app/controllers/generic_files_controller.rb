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
      ahoy.track "Object View", {title: @generic_file.title, collection: @generic_file.coll.pid, pid: params[:id], param1: @generic_file.coll.pid}
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
    session[:object_pid] = @generic_object.pid

    if session[:unsaved_generic_file].present?
      begin
        @generic_file.update(ActiveSupport::HashWithIndifferentAccess.new(session[:unsaved_generic_file]))
      rescue => ex
      end
      session[:unsaved_generic_file] = nil
    end

    @selectable_collection = []

    institutions = Institution.all.map do |u|
      {
          id: id,
          text: name
      }
    end
    @selectable_institution = institutions.sort_by { |key, val| val }.reverse
  end

  def create
    if params.key?(:upload_type) and params[:upload_type] == 'single'
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

        params[:generic_file][:title] = [params[:generic_file][:title]]
        session[:unsaved_generic_file] = params[:generic_file]
        redirect_to sufia.new_generic_file_path
      else
        #Batch.find_or_create(params[:batch_id])
        # This is a security concern... Save the pid in the session?
        form = params[:generic_object]
        @generic_object = ::GenericObject.new(form[:pid])

        # Set all fields
        @generic_object.title = form[:title]
        @generic_object.alt_titles = form[:alt_titles]
        @generic_object.creators = form[:creators]
        @generic_object.contributors = form[:contributors]
        @generic_object.date_created = form[:date_created]
        @generic_object.date_issued = form[:date_issued]
        @generic_object.temporal_coverage = form[:temporal_coverage]

        # Don't forget about depositor

        if form[:hosted_elsewhere] != "0"
          if params.key?(:filedata)
            file = params[:filedata]
            img = Magick::Image.read(file.path()).first
            img = Magick::Image.from_blob( img.to_blob { self.format = "jpg" } ).first

            if File.extname(file.original_filename) == '.pdf'
              thumb = img.resize_to_fit(500,600) #338,493
            else
              thumb = img.resize_to_fit(500,600) #FIXME?
            end

            @generic_object.add_image(thumb.to_blob, 'image/jpeg')

            # File.basename(file.original_filename,File.extname(file.original_filename))

            # Start a worker for derivative?
          end
        else
          file = params[:filedata]
          @generic_object.add_image(file.read, file.content_type)
        end

        @generic_object.collection = ::Coll.find(params[:collection])
        @generic_object.institution = ::Inst.find(params[:institution])
        @generic_object.save!

        # To do: this in the object
        ::Inst.find(params[:institution]).send_solr
        ::Coll.find(params[:collection]).send_solr

        Sufia.queue.push(CharacterizeJob.new(@generic_object.id))

        redirect_to sufia.dashboard_files_path, notice: render_to_string(partial: 'generic_files/asset_updated_flash', locals: { generic_file: @generic_object })
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
