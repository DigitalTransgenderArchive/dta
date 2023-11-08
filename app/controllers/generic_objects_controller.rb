class GenericObjectsController < ApplicationController
  include Blacklight::Catalog
  include DtaSearchHelper
  include DtaStaticBuilder

  copy_blacklight_config_from(CatalogController)
  before_action :mlt_results_for_show, :only => [:show]

  before_action :get_latest_content

  before_action :verify_contributor, except: [:show, :citation, :swap_visibility] #FIXME: Added show for now... but need to remove that...

  before_action :verify_admin, only: [:swap_visibility]

  #Needed because it attempts to load from Solr in: load_resource_from_solr of Sufia::FilesControllerBehavior
  #skip_load_and_authorize_resource :only=> [:create, :swap_visibility, :show] #FIXME: Why needed for swap visibility exactly?

  #GenericFilesController.search_params_logic += [:add_access_controls_to_solr_params, :add_advanced_parse_q_to_solr, :exclude_unwanted_models]

  # Blacklight uses #search_action_url to figure out the right URL for
  # the global search box
  def search_action_url options = {}
    search_catalog_url(options.except(:controller, :action))
  end
  helper_method :search_action_url

  # run a separate search for 'more like this' items
  # so we can explicitly set params to exclude unwanted items
  def mlt_results_for_show

    blacklight_config.search_builder_class = MltSearchBuilder
    (@mlt_response, @mlt_document_list) = search_results(mlt_id: params[:id], rows: 6)
    # have to reset to CommonwealthSearchBuilder, or prev/next links won't work
    blacklight_config.search_builder_class = DefaultSearchBuilder

  end

  def batch_edit
    (@response, @document_list) = search_results(params.except(:page, :per_page).merge(rows: 2000))
    raise 'Maximum results reached in catalog_controller... maximum change of 2000 records allowed!' if @document_list.size == 2000
    @batch_field_type = params[:batch_field_type]

    #puts 'Count was: ' + @document_list['numFound'].to_s
    #raise @response['ivars'].to_s
    #raise @response.total_pages.to_s
    #raise @document_list.size.to_s
    #raise @response.to_yaml
    #raise @document_list.to_yaml
  end

  def get_batch_objs
    (@response, @document_list) = search_results(params.except(:page, :per_page).merge(rows: 2000))
    ids = @document_list.collect {|doc| doc[:id] }
    objs = GenericObject.where(pid: ids)
    objs
  end

  def batch_add
    objs = get_batch_objs

    ActiveRecord::Base.transaction do
      objs.each do |obj|
        case params[:batch_field_type]
          when 'Genre'
            unless obj.genres.pluck(:label).include?(params[:generic_object][:new_genre])
              obj.genres = obj.genres + [params[:generic_object][:new_genre]]
              obj.save!
            end
          when 'Creator'
            if params[:generic_object][:new_creator].class == Array
              params[:generic_object][:new_creator] = params[:generic_object][:new_creator][0]
            end
            unless obj.creators.pluck(:label).include?(params[:generic_object][:new_creator])
              obj.creators = obj.creators + [params[:generic_object][:new_creator]]
              obj.save!
            end
          when 'Resource_Type'
            unless obj.resource_types.pluck(:label).include?(params[:generic_object][:delete_resource_type])
              obj.resource_types = obj.resource_types + [params[:generic_object][:new_resource_type]]
              obj.save!
            end
          else
            raise "Unsupported?"
        end
      end
    end
    flash[:notice] = "Batch Add was run on these items!"
    redirect_to search_catalog_path(request.parameters.except(:batch_field_type, :generic_object, :authenticity_token, :action, :replace_field, :add_field, :delete_field, :controller))
  end

  def batch_delete
    objs = get_batch_objs
    ActiveRecord::Base.transaction do
      objs.each do |obj|
        case params[:batch_field_type]
          when 'Genre'
            if obj.genres.pluck(:label).include?(params[:generic_object][:delete_genre])
              obj.genres.delete(Genre.find_by(label: params[:generic_object][:delete_genre]))
              obj.save!
            end
          when 'Creator'
            if params[:generic_object][:delete_creator].class == Array
              params[:generic_object][:delete_creator] = params[:generic_object][:delete_creator][0]
            end
            if obj.creators.pluck(:label).include?(params[:generic_object][:delete_creator])
              obj.creators.delete(Creator.find_by(generic_object_id: obj.id, label: params[:generic_object][:delete_creator]))
              obj.save!
            end
          when 'Resource_Type'
            if obj.resource_types.pluck(:label).include?(params[:generic_object][:delete_resource_type])
              obj.resource_types.delete(ResourceType.find_by(label: params[:generic_object][:delete_resource_type]))
              obj.save!
            end
          else
            raise "Unsupported?"
        end
      end
    end
    flash[:notice] = "Batch Delete was run on these items!"
    redirect_to search_catalog_path(request.parameters.except(:batch_field_type, :generic_object, :authenticity_token, :action, :replace_field, :add_field, :delete_field, :controller))
  end

  def batch_replace
    objs = get_batch_objs

    ActiveRecord::Base.transaction do
      objs.each do |obj|
        case params[:batch_field_type]
          when 'Genre'
            if obj.genres.pluck(:label).include?(params[:generic_object][:delete_genre])
              obj.genres.delete(Genre.find_by(label: params[:generic_object][:delete_genre]))
              obj.genres = obj.genres + [params[:generic_object][:new_genre]]
              obj.save!
            end
          when 'Creator'
            if params[:generic_object][:delete_creator].class == Array
              params[:generic_object][:delete_creator] = params[:generic_object][:delete_creator][0]
              params[:generic_object][:new_creator] = params[:generic_object][:new_creator][0]
            end
            if obj.creators.pluck(:label).include?(params[:generic_object][:delete_creator])
              obj.creators.delete(Creator.find_by(generic_object_id: obj.id, label: params[:generic_object][:delete_creator]))
              obj.creators = obj.creators + [params[:generic_object][:new_creator]]
              obj.save!
            end
          when 'Rights'
            if obj.rights.pluck(:label).include?(params[:generic_object][:delete_rights])
              obj.rights.delete(Rights.find_by(label: params[:generic_object][:delete_rights]))
              obj.rights = obj.rights + [params[:generic_object][:new_rights]]
              obj.save!
            end
          when 'Resource_Type'
            if obj.resource_types.pluck(:label).include?(params[:generic_object][:delete_resource_type])
              obj.resource_types.delete(ResourceType.find_by(label: params[:generic_object][:delete_resource_type]))
              obj.resource_types = obj.resource_types + [params[:generic_object][:new_resource_type]]
              obj.save!
            end
          else
            raise "Unsupported?"
        end
      end
    end
    flash[:notice] = "Batch Replace was run on these items!"
    redirect_to search_catalog_path(request.parameters.except(:batch_field_type, :generic_object, :authenticity_token, :action, :replace_field, :add_field, :delete_field, :action, :controller))
  end

  def batch_change
    (@response, @document_list) = search_results(params)
    raise 'Maximum results reached in catalog_controller... maximum change of 2000 records allowed!' if @document_list.size == 2000
    #puts 'Count was: ' + @document_list['numFound'].to_s
    #raise @response['ivars'].to_s
    #raise @response.total_pages.to_s
    raise @document_list.size.to_s
    raise @response.to_yaml
    raise @document_list.to_yaml
  end

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

      unless current_user.present? and current_user.contributor?
        ahoy.track_visit
        ahoy.track "Object View", {title: @generic_file.title}, {collection_pid: @generic_file.coll.pid, institution_pid: @generic_file.inst.pid, pid: params[:id], model: "GenericObject", search_term: search_term}
      end

      respond_to do |format|
        format.html do
          setup_next_and_previous_documents
          @show_response, @document = fetch(params[:id])
          @response = @show_response # Hack to support bookmarks
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

  def set_object(form_fields)
    @generic_object.title = form_fields[:title].strip

    if form_fields[:alt_titles][0].present?
      @generic_object.alt_titles = form_fields[:alt_titles].reject { |c| c.empty? }.map(&:strip)
    elsif @generic_object.alt_titles.present?
      @generic_object.alt_titles = []
    end

    if form_fields[:creators][0].present?
      @generic_object.creators = form_fields[:creators].reject { |c| c.empty? }.map(&:strip)
    elsif @generic_object.creators.present?
      @generic_object.creators = []
    end

    if form_fields[:contributors][0].present?
      @generic_object.contributors = form_fields[:contributors].reject { |c| c.empty? }.map(&:strip)
    elsif @generic_object.contributors.present?
      @generic_object.contributors = []
    end

    if form_fields[:date_created][0].present?
      @generic_object.date_created = form_fields[:date_created].reject { |c| c.empty? }
    elsif @generic_object.date_created.present?
      @generic_object.date_created = []
    end

    if form_fields[:date_issued][0].present?
      @generic_object.date_issued = form_fields[:date_issued].reject { |c| c.empty? }
    elsif @generic_object.date_issued.present?
      @generic_object.date_issued = []
    end

    if form_fields[:temporal_coverage][0].present?
      @generic_object.temporal_coverage = form_fields[:temporal_coverage].reject { |c| c.empty? }
    elsif @generic_object.temporal_coverage.present?
      @generic_object.temporal_coverage = []
    end



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
    #form_fields[:homosaurus_v2_subjects].each_with_index do |s, index|
    #  if s.present?
    #    form_fields[:homosaurus_v2_subjects][index] = s.split('(').last
    #    form_fields[:homosaurus_v2_subjects][index].gsub!(/\)$/, '')
    #  end
    #end
    form_fields[:homosaurus_uri_subjects].each_with_index do |s, index|
      if s.present?
        form_fields[:homosaurus_uri_subjects][index] = s.split('(').last
        form_fields[:homosaurus_uri_subjects][index].gsub!(/\)$/, '')
      end
    end

    if form_fields[:geonames][0].present?
      @generic_object.geonames = form_fields[:geonames].reject { |c| c.empty? }
    elsif @generic_object.geonames.present?
      @generic_object.geonames = []
    end

    if form_fields[:homosaurus_subjects][0].present?
      @generic_object.homosaurus_subjects = form_fields[:homosaurus_subjects].reject { |c| c.empty? }
    elsif @generic_object.homosaurus_subjects.present?
      @generic_object.homosaurus_subjects = []
    end

    # if form_fields[:homosaurus_v2_subjects][0].present?
    #  @generic_object.homosaurus_v2_subjects = form_fields[:homosaurus_v2_subjects].reject { |c| c.empty? }
    #elsif @generic_object.homosaurus_v2_subjects.present?
    #  @generic_object.homosaurus_v2_subjects = []
    #end

    if form_fields[:homosaurus_uri_subjects][0].present?
      @generic_object.homosaurus_uri_subjects = form_fields[:homosaurus_uri_subjects].reject { |c| c.empty? }
    elsif @generic_object.homosaurus_uri_subjects.present?
      @generic_object.homosaurus_uri_subjects = []
    end

    if form_fields[:lcsh_subjects][0].present?
      @generic_object.lcsh_subjects = form_fields[:lcsh_subjects].reject { |c| c.empty? }
    elsif @generic_object.lcsh_subjects.present?
      @generic_object.lcsh_subjects = []
    end

    if form_fields[:other_subjects][0].present?
      @generic_object.other_subjects = form_fields[:other_subjects].reject { |c| c.empty? }.map(&:strip)
    elsif @generic_object.other_subjects.present?
      @generic_object.other_subjects = []
    end

    @generic_object.flagged = form_fields[:flagged]

    if form_fields[:analog_format][0].present?
      @generic_object.analog_format = form_fields[:analog_format]
    elsif @generic_object.analog_format.present?
      @generic_object.analog_format = nil
    end

    if form_fields[:digital_format][0].present?
      @generic_object.digital_format = form_fields[:digital_format]
    elsif @generic_object.digital_format.present?
      @generic_object.digital_format = nil
    end

    if form_fields[:descriptions][0].present?
      @generic_object.descriptions = form_fields[:descriptions].reject { |c| c.empty? }.map(&:strip)
    elsif @generic_object.descriptions.present?
      @generic_object.descriptions = []
    end

    # TOC is submitted as a single field
    # Likely should not be appending "0" index for this
    if form_fields[:toc][0].present?
      @generic_object.toc = form_fields[:toc].strip
    elsif @generic_object.toc.present?
      @generic_object.toc = nil
    end

    if form_fields[:languages][0].present?
      @generic_object.languages = form_fields[:languages].reject { |c| c.empty? }
    elsif @generic_object.languages.present?
      @generic_object.languages = []
    end

    if form_fields[:publishers][0].present?
      @generic_object.publishers = form_fields[:publishers].reject { |c| c.empty? }.map(&:strip)
    elsif @generic_object.publishers.present?
      @generic_object.publishers = []
    end

    if form_fields[:related_urls][0].present?
      @generic_object.related_urls = form_fields[:related_urls].reject { |c| c.empty? }.map(&:strip)
    elsif @generic_object.related_urls.present?
      @generic_object.related_urls = []
    end

    # This likely shouldn't be checking index 0...
    if form_fields[:rights][0].present?
      @generic_object.rights = form_fields[:rights]
    elsif @generic_object.rights.present?
      @generic_object.rights = nil
    end

    if form_fields[:rights_free_text][0].present?
      @generic_object.rights_free_text = form_fields[:rights_free_text].reject { |c| c.empty? }.map(&:strip)
    elsif @generic_object.rights_free_text.present?
      @generic_object.rights_free_text = []
    end

    if form_fields[:is_shown_at][0].present?
      @generic_object.is_shown_at = form_fields[:is_shown_at].strip
    elsif @generic_object.is_shown_at.present?
      @generic_object.is_shown_at = nil
    end

    if form_fields[:resource_types][0].present?
      @generic_object.resource_types = form_fields[:resource_types].reject { |c| c.empty? }
    elsif @generic_object.resource_types.present?
      @generic_object.resource_types = []
    end

    @generic_object.depositor = current_user.to_s

    @generic_object.hosted_elsewhere = form_fields[:hosted_elsewhere]

    # These were missing
    @generic_object.genres = form_fields[:genres].reject { |c| c.empty? }

    # This is for hist
    #STEVEN: @generic_object.hist_whodunnit = current_user.to_s


    @generic_object.inst = Inst.find_by(pid: params[:institution])
    @generic_object.coll = Coll.find_by(pid: params[:collection])
  end

  def create
    if params.key?(:upload_type) and params[:upload_type] == 'single'
      unless validate_metadata(params, 'create')
        session[:unsaved_generic_object] = params[:generic_object]
        #redirect_to new_generic_object_path
        redirect_back(fallback_location: new_generic_object_path)
      else

        @generic_object = GenericObject.find_or_initialize_by(pid: params[:pid])
        #@generic_object = GenericObject.new
        form_fields = params['generic_object']

        self.set_object(form_fields)

        @generic_object.visibility = "private"

        if params[:generic_object][:hosted_elsewhere] != "0"
          if params.key?(:filedata)
            files = params[:filedata]
            files.each do |file|
              image = MiniMagick::Image.open(file.path())

              if File.extname(file.original_filename) == '.pdf'
                image.format('jpg', 0, {density: '300'})
              else
                image.format "jpg"
              end

              image.resize "500x600"

              @generic_object.add_file(image.to_blob, 'image/jpeg', File.basename(file.original_filename,File.extname(file.original_filename)))
            end
          end
        else
          files = params[:filedata]
          files.each do |file|
            @generic_object.add_file(File.open(file.path(), 'rb').read, file.content_type, file.original_filename)
          end
        end

        @generic_object.save!

        # Make this better
        @generic_object.coll.send_solr
        @generic_object.inst.send_solr

        #ProcessFileWorker.perform_async(@generic_object.base_files[0].id)
        @generic_object.base_files.each do |file|
          file.create_derivatives
        end

        # Fixme... would be best if this was after derivatives
        @generic_object.reload
        @generic_object.send_solr

        redirect_to generic_object_path(@generic_object.pid), notice: "This object has been created."
      end

    end
  end

  def update
    if params.key?(:upload_type) and params[:upload_type] == 'single'
      @generic_object = GenericObject.find(params[:id])

      unless validate_metadata(params, 'update')
        #raise params[:generic_object][:temporal_coverage].to_s
        redirect_back(fallback_location: edit_generic_object_path(@generic_object.pid))
      else
        ActiveRecord::Base.transaction do

          form_fields = params['generic_object']
          # There is a bug with completely removing a value
          self.set_object(form_fields)

          @generic_object.base_files.clear
          if form_fields['existing_file'].present?
            form_fields['existing_file'].each do |file_id|
              @generic_object.base_files << BaseFile.find(file_id)
            end
          end


          if params.key?(:filedata)
            # FIXME: This does it before save...


            files = params[:filedata]

            if params[:generic_object][:hosted_elsewhere] != "0"
              files.each do |file|
                image = MiniMagick::Image.open(file.path())

                if File.extname(file.original_filename) == '.pdf'
                  image.format('jpg', 0, {density: '300'})
                else
                  image.format "jpg"
                end

                image.resize "500x600"

                @generic_object.add_file(image.to_blob, 'image/jpeg', File.basename(file.original_filename,File.extname(file.original_filename)))
              end

            else
              files.each do |file|
                @generic_object.add_file(File.open(file.path(), 'rb').read, file.content_type, file.original_filename)
              end
            end
          end

          @generic_object.save!

          if params.key?(:filedata)
            @generic_object.base_files.each do |file|
              file.create_derivatives
            end
          end

          # Make this better
          @generic_object.coll.send_solr
          @generic_object.inst.send_solr

          redirect_to generic_object_path(@generic_object.pid), notice: "This object has been updated."
        end
      end
    end
  end

  def destroy
    GenericObject.find_by(pid: params[:id]).destroy!
    redirect_to root_path, notice: "This object has been removed from the system."
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

  def swap_visibility
    obj = GenericObject.find_by(pid: params[:id])
    if obj.visibility == 'private'
      obj.visibility = 'public'
    else
      obj.visibility = 'private'
    end
    obj.save!
    flash[:notice] = "Visibility of object was changed!"
    redirect_to generic_object_path(obj.pid)
    #redirect_to request.referrer
  end

  def regenerate_thumbnail
    obj = GenericObject.find_by(pid: params[:id])
    obj.base_files[0].create_derivatives
    obj.send_solr
    flash[:notice] = "Thumbnail was regenerated!"
    redirect_to generic_object_path(obj.pid)
  end

  def make_coll_image
    obj = GenericObject.find_by(pid: params[:id])
    coll = obj.coll
    if coll.present?
      coll.generic_object = obj
      coll.save!
    else
      raise 'Error: This object does not have a collection?'
    end
    flash[:notice] = "This collection has had its image updated!"
    redirect_to collection_path(coll.pid)
  end

  def edit
    if params[:version_id].present?
      @generic_object = Hist::Version.find(params[:version_id]).reify
    else
      @generic_object = GenericObject.find_by(pid: params[:id])
    end

    institutions = Inst.all.pluck(:name, :pid)
    @selectable_institution = institutions.sort_by { |key, val| key }

    @institution_id = @generic_object.inst.pid
    @collection_id = @generic_object.coll.pid

    @selectable_collection = []
    @selectable_collection = @generic_object.inst.colls.pluck(:title, :pid)
    @selectable_collection.uniq!
    @selectable_collection = @selectable_collection.sort_by { |key, val| key }
  end
  
end
