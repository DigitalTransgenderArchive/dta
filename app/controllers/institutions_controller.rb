class InstitutionsController < ApplicationController
  include Blacklight::Catalog
  include DtaSearchHelper
  include DtaStaticBuilder

  copy_blacklight_config_from(CatalogController)

  before_action :get_latest_content

  before_action :update_search_builder, only: [:index]
  #before_action :update_show_search_builder, only: [:show]

  before_action :verify_admin, except: [:index, :show, :facet]
  before_action :verify_superuser, only: [:destroy, :edit]

  #include Blacklight::Configurable
  #include Blacklight::SearchHelper

  before_action :remove_unwanted_views, :only => [:index]

  # remove collection facet and collapse others
  before_action :institution_base_blacklight_config, :only => [:show]

  before_action :add_catalog_folder, only: [:index, :show, :facet]

  before_action  only: :show do
    if current_user.present? and current_user.contributor?
      blacklight_config.add_facet_field 'visibility_ssi', :label => 'Visibility', :limit => 3, :collapse => false
    end
  end

  def update_show_search_builder
    blacklight_config.search_builder_class = ::InstitutionShowSearchBuilder
  end

  def update_collections
    term_query = DSolr.find({q: "isMemberOfCollection_ssim:#{params[:id]} AND model_ssi:Collection", rows: '10000', fl: 'id,title_tesim'})
    term_query = term_query.sort_by { |term| term["title_tesim"].first }
    @selectable_collection = []
    term_query.each { |term| @selectable_collection << [term["title_tesim"].first, term["id"]] }

    respond_to do |format|
      if @selectable_collection.present?
        format.html { render html: @selectable_collection.to_s }
        format.json { render json: @selectable_collection.to_json, status: :created }
      else
        format.html { render action: "new" }
        format.json { render json: @selectable_collection, status: :unprocessable_entity }
      end
    end

  end

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

    # blacklight-maps stuff
    # blacklight_config.view.maps.geojson_field = 'inst_geojson_hash_ssi'
    # blacklight_config.view.maps.coordinates_field = 'inst_coordinates_geospatial'
    # blacklight_config.view.maps.placename_field = 'institution_name_ssim'
    # blacklight_config.view.maps.maxzoom = 13
    # blacklight_config.view.maps.show_initial_zoom = 9
    # blacklight_config.view.maps.facet_mode = 'geojson'
    # blacklight_config.views.maps.catalogpath = 'inst'

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
    #@collex_response, @collex_documents = search_results({:f => {'model_ssi' => 'Collection','institution_pid_ssi' => params[:id]},:rows => 100, :sort => 'title_info_ssort asc'})
    @collex_documents = DSolr.find({q:"model_ssi:Collection and institution_pid_ssim:#{params[:id]}",:rows => 100, :sort => 'title_info_ssort asc'})
    @collex_documents.each_with_index do |hash, index|
      @collex_documents[index].merge!(@collex_documents[index].symbolize_keys)
    end
    # add params[:f] for proper facet links
    params[:f] = {blacklight_config.institution_field => [@institution.name]}

    # get the response for the facets representing items in collection
    (@response, @document_list) = search_results({:f => params[:f]})

    unless current_user.present? and current_user.contributor?
      ahoy.track_visit
      ahoy.track "Institution View", {title: @institution.name}, {pid: params[:id], model: "Institution"}
    end

    respond_to do |format|
      format.html
    end
  end

  def new
    @institution = Inst.new
  end

  def create
    @institution = Inst.new(institution_params)

    @institution.visibility = 'private'

    if params.key?(:filedata)
      file = params[:filedata]
      @institution.add_image(File.open(file.path(), 'rb').read, file.content_type, file.original_filename)
    end

    if @institution.save
      redirect_to institution_path(:id => @institution.pid)
    else
      redirect_to new_institution_path
    end
  end

  def edit
    @institution = Inst.find_by(pid: params[:id])
  end

  def update
    @institution = Inst.find_by(pid: params[:id])

    @institution.update(institution_params)

    if params.key?(:filedata)
      file = params[:filedata]
      @institution.inst_image_files[0].delete
      @institution.add_image(File.open(file.path(), 'rb').read, file.content_type, file.original_filename)
    end

    if @institution.save
      redirect_to institution_path(:id => @institution.pid), notice: "Institution was updated!"
    else
      redirect_to new_institution_path
    end
  end

  def destroy
    #do nothing at fist
    @institution = Inst.find_by(pid: params[:id])

    @institution.destroy!

    redirect_to institutions_path, notice: "Institution was deleted!"
  end


  def institution_params
    params.require(:institution).permit(:name, :description, :contact_person, :address, :email, :phone, :institution_url, :pid, :lat, :lng, :visibility)
  end
end
