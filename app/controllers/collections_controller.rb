class CollectionsController < ApplicationController
  include Blacklight::Catalog
  include DtaSearchHelper
  include DtaStaticBuilder

  copy_blacklight_config_from(CatalogController)

  before_action :update_search_builder
  #before_action :has_access?, except: [:show, :public_index, :public_show, :facet]
  #before_action :build_breadcrumbs, only: [:edit, :show, :public_show, :facet]
  #before_filter :authenticate_user!, :except => [:show, :public_index, :public_show, :facet]

  before_action :collection_base_blacklight_config, :only => [:show, :public_show, :facet]

  before_action :verify_admin, except: [:show, :public_index, :public_show, :facet] #FIXME on change member

  #skip_load_and_authorize_resource :only => [:index, :facet], instance_name: :collection

  def update_search_builder
    blacklight_config.search_builder_class = ::CollectionSearchBuilder
  end

  def index

  end

  def show
    super
  end

  def destroy
    if @collection.member_ids.present?
      raise "Cannot delete a collection with items associated with it"
    end

    super
  end

  #override
  def add_members_to_collection collection = nil
    collection ||= @collection
    return if batch.nil? || batch.size < 1
    items = ActiveFedora::Base.find(batch)
    items.each do |item|
      item.institutions.each do |inst|
        acquire_lock_for(inst.id) do
          inst.reload
          inst.files.delete(item)
          #inst.save
        end
      end

      item.collections.each do |coll|
        acquire_lock_for(coll.id) do
          coll.reload
          coll.members.delete(item)
          #coll.save
        end
      end

      item.institutions = []
      item.collections = []
    end

    acquire_lock_for(collection.id) do
      collection.reload
      collection.members << items
      collection.save
    end

    acquire_lock_for(collection.institutions.first.id) do
      collection.institutions.first.reload
      collection.institutions.first.files << items
      collection.institutions.first.save
    end

    items.each do |item|
      item = GenericFile.find(item.id)
      item.update_index
    end
  end

  def public_show
    @nav_li_active = 'explore'
    @show_response, @document = fetch(params[:id])

    # add params[:f] for proper facet links
    params[:f] = set_collection_facet_params(@collection_title, @document)

    # get the response for the facets representing items in collection
    (@response, @document_list) = search_results({:f => params[:f]})

    respond_to do |format|
      format.html
    end
  end

  # set the correct facet params for facets from the collection
  def set_collection_facet_params(collection_title, document)
    facet_params = {blacklight_config.collection_field => [collection_title]}
    #facet_params[blacklight_config.institution_field] = document[blacklight_config.institution_field.to_sym]
    facet_params
  end

  # Blacklight uses #search_action_url to figure out the right URL for
  # the global search box
  def search_action_url options = {}
    search_catalog_url(options.except(:controller, :action))
  end
  helper_method :search_action_url

  def public_index
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

  def after_update
    if @reindex_members
      @collection.members.each do |file|
        file.update_index
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
