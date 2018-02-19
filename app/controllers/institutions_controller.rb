class InstitutionsController < ApplicationController
  include Blacklight::Catalog
  include DtaSearchHelper
  include DtaStaticBuilder

  copy_blacklight_config_from(CatalogController)

  before_action :update_search_builder, only: [:index]

  before_action :verify_admin, except: [:index, :show, :facet]
  before_action :verify_superuser, only: [:destroy, :edit]

  #include Blacklight::Configurable
  #include Blacklight::SearchHelper

  before_action :remove_unwanted_views, :only => [:index]

  # remove collection facet and collapse others
  before_action :institution_base_blacklight_config, :only => [:show]

  before_action :add_catalog_folder, only: [:index, :show, :facet]

  # FIXME... this isn't working?
=begin
  def render_body_class
    'blacklight-institution'
  end
=end

  # Blacklight uses #search_action_url to figure out the right URL for
  # the global search box
  def search_action_url options = {}
    search_catalog_url(options.except(:controller, :action))
  end
  helper_method :search_action_url

  def update_search_builder
    blacklight_config.search_builder_class = ::InstitutionSearchBuilder
  end

  def institution_base_blacklight_config
    # don't show collection facet
    @skip_dta_limits_render = true
    blacklight_config.facet_fields['collection_name_ssim'].show = false
    blacklight_config.facet_fields['collection_name_ssim'].if = false

    blacklight_config.facet_fields['institution_name_ssim'].show = false
    blacklight_config.facet_fields['institution_name_ssim'].if = false

    #Needs to be fixed...
    blacklight_config.facet_fields['dta_dates_ssim'].show = false
    blacklight_config.facet_fields['dta_dates_ssim'].if = false

    # collapse remaining facets
    #blacklight_config.facet_fields['subject_facet_ssim'].collapse = true
    #blacklight_config.facet_fields['subject_geographic_ssim'].collapse = true
    #blacklight_config.facet_fields['date_facet_ssim'].collapse = true
    #blacklight_config.facet_fields['genre_basic_ssim'].collapse = true
  end

  # remove grid view from blacklight_config for index view
  def remove_unwanted_views
    blacklight_config.view.delete(:gallery)
    blacklight_config.view.delete(:masonry)
    blacklight_config.view.delete(:slideshow)
  end

  def index
    @nav_li_active = 'explore'
    (@response, @document_list) = search_results({:f => {'model_ssi' => 'Institution'},:rows => 300, :sort => 'title_primary_ssort asc'})

    params[:view] = 'list'
    params[:sort] = 'title_primary_ssort asc'

    respond_to do |format|
      format.html
    end
  end

  def show
    @nav_li_active = 'explore'
    @show_response, @document = fetch(params[:id])
    @institution = Inst.find_by(pid: params[:id])

    # get the response for collection objects
    @collex_response, @collex_documents = search_results({:f => {'model_ssi' => 'Collection','institution_pid_ssi' => params[:id]},:rows => 100, :sort => 'title_info_ssort asc'})

    # add params[:f] for proper facet links
    params[:f] = {blacklight_config.institution_field => [@institution.name]}

    # get the response for the facets representing items in collection
    (@response, @document_list) = search_results({:f => params[:f]})

    ahoy.track_visit
    ahoy.track "Institution View", {title: @institution.name}, {pid: params[:id], model: "Institution"}

    respond_to do |format|
      format.html
    end
  end

  def new
    @institution = Institution.new
    collection_query = Collection.find_with_conditions("*:*", rows: '100000', fl: 'id,title_tesim' )
    @all_collections = []
    collection_query.each { |term| @all_collections << [term["title_tesim"], term["id"]] }

  end

  def create
    @institution = Institution.new(institution_params)

    current_time = Time.now
    @institution.date_created =   current_time.strftime("%Y-%m-%d")
    @institution.permissions_attributes = [{ type: 'group', name: 'public', access: 'read' }, {type: 'group', name: 'admin', access: 'edit'}, {type: 'group', name: 'superuser', access: 'edit'}]
    @institution.visibility = 'public'

    if params.key?(:filedata)
      file = params[:filedata]
      @institution.add_file(file, path: 'content', original_name: file.original_filename, mime_type: file.content_type)
    end

=begin
    if params[:homosaurus][:broader_ids].present?
      params[:homosaurus][:broader_ids].each do |broader|
        if broader.present?
          broader_object = Homosaurus.find(broader)
          @homosaurus.broader = @homosaurus.broader + [broader_object]
          broader_object.narrower = broader_object.narrower + [@homosaurus]
          broader_object.save
        end
      end
    end
=end


    if @institution.save
      redirect_to institution_path(:id => @institution.id)
    else
      redirect_to new_institution_path
    end
  end

  def edit
    @institution = Institution.find(params[:id])
    collection_query = Collection.find_with_conditions("*:*", rows: '100000', fl: 'id,title_tesim' )
    @all_collections = []
    collection_query.each { |term| @all_collections << [term["title_tesim"], term["id"]] }
  end

  def update
    @reindex_members = false
    @institution = Institution.find(params[:id])

    if @institution.label != params[:institution][:name]
      @reindex_members = true
    end

    @institution.update(institution_params)

    if params.key?(:filedata)
      file = params[:filedata]
      @institution.add_file(file, path: 'content', original_name: file.original_filename, mime_type: file.content_type)
    end

    if @reindex_members
      @institution.files.each do |file|
        file.update_index
      end
    end


=begin
    if params[:homosaurus][:broader_ids].present?
      params[:homosaurus][:broader_ids].each do |broader|
        if broader.present?
          broader_object = Homosaurus.find(broader)
          @homosaurus.broader = @homosaurus.broader + [broader_object]
          broader_object.narrower = broader_object.narrower + [@homosaurus]
          broader_object.save
        end
      end
    end
=end


    if @institution.save
      redirect_to institution_path(:id => @institution.id), notice: "Institution was updated!"
    else
      redirect_to new_institution_path
    end
  end

  def destroy
    #do nothing at fist
    @institution = Institution.find(params[:id])

    @institution.members.each do |coll|
      #acquire_lock_for(coll.id) do
        @institution.reload
        @institution.members.delete(coll)
        coll.update_index
      #end

    end

    @institution.files.each do |file|
      file.institutions.delete(@institution)
      file.save
    end

    @institution.reload

    @institution.delete

    redirect_to institutions_path, notice: "Institution was deleted!"
  end


  def institution_params
    params.require(:institution).permit(:name, :description, :contact_person, :address, :email, :phone, :institution_url)
  end
end
