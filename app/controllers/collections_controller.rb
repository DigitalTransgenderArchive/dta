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
      blacklight_config.add_facet_field 'visibility_ssi', :label => 'Visibility', :limit => 4, :collapse => false
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
    blacklight_config.facet_fields['dta_dates_yearly_itim'].show = false
    blacklight_config.facet_fields['dta_dates_yearly_itim'].if = false
  end

  def range_limit
    redirect_to range_limit_catalog_path(params.except('controller', 'action')) and return
  end

  def index
    @nav_li_active = 'explore'
    (@response, @document_list) = search_results({:f => {'model_ssi' => 'Collection'}, :rows => 300, :sort => 'title_primary_ssort asc'})

=begin
    if params[:filter].present?
      new_doc_list = []
      @document_list.each do |doc|
        new_doc_list << doc if doc['title_primary_ssi'].upcase[0] == params[:filter]
      end
      @document_list = new_doc_list
    end
=end
    if params[:filter].present?
      new_document_list = []
      filter_list = params[:filter].split(',')
      @document_list.each do |doc|
        if filter_list.include?(doc['title_primary_ssi'].gsub(/^The /, "").upcase[0])
          new_document_list << doc
        end
      end
      @document_list = new_document_list
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
    # unless current_user.present? and current_user.contributor?
    #  ahoy.track_visit
    #  ahoy.track "Collection View", {title: @collection.title}, {pid: params[:id], model: "Collection"}
    # end

    respond_to do |format|
      format.html
    end
  end

  def destroy
    @collection = Coll.find_by(pid: params[:id])
    #@collection.generic_objects.each do |obj|
    #obj.soft_delete
    #end
    #@collection.visibility = 'deleted'
    if @collection.generic_objects.present?
      raise "Cannot delete a collection with items associated with it."
    else
      @collection.destroy!
      flash[:notice] = "Collection was deleted."
      redirect_to collections_path
    end
  end


  # set the correct facet params for facets from the collection
  def set_collection_facet_params(collection_title, document)
    facet_params = {blacklight_config.collection_field => [collection_title]}
    #facet_params[blacklight_config.institution_field] = document[blacklight_config.institution_field.to_sym]
    facet_params
  end

  def new
    @collection = Coll.new
  end

  def edit
    @collection = Coll.find_by(pid: params[:id])
  end

  def create
    @collection = Coll.new(collection_params)
    @collection.insts = Inst.where(pid: params['collection']['insts'])
    @collection.visibility = 'private'

    if @collection.save
      redirect_to collection_path(:id => @collection.pid), notice: "Collection was created!"
    else
      redirect_to new_collection_path
    end
  end


  def update
    @collection = Coll.find_by(pid: params[:id])

    @collection.update(collection_params)
    @collection.insts = Inst.where(pid: params['collection']['insts'])

    if @collection.save
      redirect_to collection_path(:id => @collection.pid), notice: "Collection was updated!"
    else
      redirect_to new_collection_path
    end
  end

  def members_public
    collection = Coll.find_by(pid: params[:id])
    collection.generic_objects.each do |obj|
      if obj.visibility == 'private'
        obj.visibility = 'public'
        obj.save!
      end
    end

    if collection.visibility == 'private'
      collection.visibility = 'public'
      collection.save!
    end

    flash[:notice] = "Visibility of all objects was made public!"
    redirect_to request.referrer
  end

  def members_private
    collection = Coll.find_by(pid: params[:id])
    collection.generic_objects.each do |obj|
      if obj.visibility == 'public'
        obj.visibility = 'private'
        obj.save!
      end
    end

    if collection.visibility == 'public'
      collection.visibility = 'private'
      collection.save!
    end

    flash[:notice] = "Visibility of all objects was made private!"
    redirect_to request.referrer
  end

  # FIXME
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


  def collection_params
    params.require(:collection).permit(:title, :description, :pid, :visibility)
  end

end
