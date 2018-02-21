class CollectionsController < ApplicationController
  include Blacklight::Catalog
  include DtaSearchHelper
  include DtaStaticBuilder

  copy_blacklight_config_from(CatalogController)

  before_action :get_latest_content

  before_action :update_search_builder, only: :index

  before_action :authenticate_user!, :except => [:show, :index, :facet]

  before_action :collection_base_blacklight_config, :only => [:show, :public_show, :facet]

  before_action :verify_admin, except: [:show, :index, :facet] #FIXME on change member

  #skip_load_and_authorize_resource :only => [:index, :facet], instance_name: :collection

  before_action :add_catalog_folder, only: [:index, :show, :facet]

  before_action  only: :show do
    if current_user.present? and current_user.contributor?
      blacklight_config.add_facet_field 'visibility_ssi', :label => 'Visibility', :limit => 3, :collapse => false
    end
  end

  # Blacklight uses #search_action_url to figure out the right URL for
  # the global search box
  def search_action_url options = {}
    search_catalog_url(options.except(:controller, :action))
  end
  helper_method :search_action_url

  def update_search_builder
    blacklight_config.search_builder_class = ::CollectionSearchBuilder
  end

  def collection_base_blacklight_config
    @skip_dta_limits_render = true
    blacklight_config.facet_fields['collection_name_ssim'].show = false
    blacklight_config.facet_fields['collection_name_ssim'].if = false

    blacklight_config.facet_fields['institution_name_ssim'].show = false
    blacklight_config.facet_fields['institution_name_ssim'].if = false

    #Needs to be fixed...
    blacklight_config.facet_fields['dta_dates_ssim'].show = false
    blacklight_config.facet_fields['dta_dates_ssim'].if = false
  end

  def range_limit
    redirect_to range_limit_catalog_path(params.except('controller', 'action')) and return
  end

  def index
    @nav_li_active = 'explore'
    (@response, @document_list) = search_results({:f => {'model_ssi' => 'Collection'}, :rows => 300, :sort => 'title_primary_ssort asc'})

    if params[:filter].present?
      new_doc_list = []
      @document_list.each do |doc|
        new_doc_list << doc if doc['title_primary_ssi'].upcase[0] == params[:filter]
      end
      @document_list = new_doc_list
    end

    params[:view] = 'list'
    params[:sort] = 'title_info_primary_ssort asc'

    respond_to do |format|
      format.html
    end
  end

  def show
    @nav_li_active = 'explore'
    @show_response, @document = fetch(params[:id])

    # Get the ActiveRecord for this collection
    @collection = Coll.find_by(pid: params[:id])

    # add params[:f] for proper facet links
    params[:f] = set_collection_facet_params(@collection.title, @document)

    # get the response for the facets representing items in collection
    (@response, @document_list) = search_results({:f => params[:f]})
    unless current_user.present? and current_user.contributor?
      ahoy.track_visit
      ahoy.track "Collection View", {title: @collection.title}, {pid: params[:id], model: "Collection"}
    end

    respond_to do |format|
      format.html
    end
  end

  def destroy
    if @collection.member_ids.present?
      raise "Cannot delete a collection with items associated with it"
    end

    super
  end

  # set the correct facet params for facets from the collection
  def set_collection_facet_params(collection_title, document)
    facet_params = {blacklight_config.collection_field => [collection_title]}
    #facet_params[blacklight_config.institution_field] = document[blacklight_config.institution_field.to_sym]
    facet_params
  end

  def new
    term_query = Institution.find_with_conditions("*:*", rows: '10000', fl: 'id,name_ssim' )
    term_query = term_query.sort_by { |term| term["name_ssim"].first }
    @all_institutions = []
    term_query.each { |term| @all_institutions << [term["name_ssim"].first, term["id"]] }

    flash[:notice] = nil if flash[:notice] == "Select something first"
    super
  end

  def edit
    @collection_id = @collection.id
    term_query = Institution.find_with_conditions("*:*", rows: '10000', fl: 'id,name_ssim' )
    term_query = term_query.sort_by { |term| term["name_ssim"].first }
    @all_institutions = []
    term_query.each { |term| @all_institutions << [term["name_ssim"].first, term["id"]] }
    super
  end

  def update
    #Update is called from other areas like moving an item to a collection... need to fix that...
    @reindex_members = false
    if params[:collection][:institution_ids].present?
      @collection.institutions.each do |institution|
        institution.members.delete(@collection)
        institution.save
      end
      @collection.reload
      @collection.institutions = []

      params[:collection][:institution_ids].each do |institution_id|
        institution = Institution.find(institution_id)
        @collection.institutions = @collection.institutions + [institution]
        institution.members = institution.members + [@collection]
        institution.save
      end

      if @collection.title != params[:collection][:title]
        @reindex_members = true
      end
    #FIXME: Detect updates outside of collection form elsewhere...
    else
      if params[:collection][:members] == "add"
        params["batch_document_ids"].each do |pid|
          collection_query = Collection.find_with_conditions("hasCollectionMember_ssim:#{pid}", rows: '100000', fl: 'id' )
          collection_query.each do |collect_pid|
            collect_obj = Collection.find(collect_pid["id"])
            collect_obj.members.delete(ActiveFedora::Base.find(pid))
            collect_obj.save
          end
        end
      end
    end


    super
  end

  def create
    current_time = Time.now
    @collection[:date_created] =   [current_time.strftime("%Y-%m-%d")]
    #Contributor not being saved.... , {type: 'group', name: 'contributor', access: 'read'}
    @collection.permissions_attributes = [{type: 'group', name: 'admin', access: 'edit'}, {type: 'group', name: 'superuser', access: 'edit'}]
    #@collection.visibility = 'restricted'
    if params[:collection][:institution_ids].present?
      params[:collection][:institution_ids].each do |institution_id|
        institution = Institution.find(institution_id)
        @collection.institutions = @collection.institutions + [institution]
        #institution.members = institution.members + [@collection]

      end
    end

    super
  end

  def collection_thumbnail_set
    if @collection.thumbnail_ident != params[:item_id]
      @collection.thumbnail_ident = params[:item_id]
      @collection.save
      flash[:notice] = "Collection Image Was Set!"
    else
      flash[:notice] = "Could not set collection image (perhaps this was already set?)"
    end

    redirect_to request.referrer
  end

  def change_member_visibility
    collection = ActiveFedora::Base.find(params[:id])
    collection.members.each do |obj|
      if obj.visibility == 'restricted'
        obj.visibility = 'open'
        obj.save
      end
    end

    if collection.visibility == 'restricted'
      collection.visibility = 'open'
      collection.save
    end

    flash[:notice] = "Visibility of all objects was changed!"
    redirect_to request.referrer
  end

  def collection_invisible
    collection = ActiveFedora::Base.find(params[:id])

    collection.members.each do |obj|
      if obj.visibility == 'open'
        obj.visibility = 'restricted'
        obj.save
      end
    end

    collection.visibility = 'restricted'
    collection.save

    flash[:notice] = "Visibility of collection and all objects now private!"
    redirect_to request.referrer
  end

  def collection_visible
    collection = ActiveFedora::Base.find(params[:id])
    collection.visibility = 'open'
    collection.save

    flash[:notice] = "Collection now set to public!"
    redirect_to request.referrer
  end

  def collection_params
    form_class.model_attributes(
        params.require(:collection).permit(:title, :description, :members, :date_created)
    )
  end

end
