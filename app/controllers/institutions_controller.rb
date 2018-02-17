class InstitutionsController < ApplicationController
  include CatalogLikeBehavior
  include DtaStaticBuilder

  #before_action :verify_admin, except: [:public_index, :public_show, :facet]
  #before_action :verify_superuser, only: [:destroy, :edit]

  #include Blacklight::Configurable
  #include Blacklight::SearchHelper



  before_action :remove_unwanted_views, :only => [:public_index]

  # remove collection facet and collapse others
  #before_filter :institution_base_blacklight_config, :only => [:public_show]


  def enforce_show_permissions
    #DO NOTHING
  end
  # remove grid view from blacklight_config for index view
  def remove_unwanted_views
    blacklight_config.view.delete(:gallery)
    blacklight_config.view.delete(:masonry)
    blacklight_config.view.delete(:slideshow)
  end

  def update_collections
    term_query = DSolr.find({q: "isMemberOfCollection_ssim:#{params[:id]} and model_ssi:Collection", rows: '10000', fl: 'id,title_tesim' })
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

  def index
    #@terms = Homosaurus.all.sort_by { |term| term.preferred_label }
    #@terms = Homosaurus.all
    @institutions = Institution.find_with_conditions("*:*", rows: '1000', fl: 'id,name_ssim' )
    @institutions = @institutions.sort_by { |term| term["name_ssim"].first }
  end

  def show
    @institution = Institution.find(params[:id])

    respond_to do |format|
      format.html
      #format.nt { render body: @homosaurus.full_graph.dump(:ntriples), :content_type => Mime::NT }
      #format.jsonld { render body: @homosaurus.full_graph.dump(:jsonld, standard_prefixes: true), :content_type => Mime::JSONLD }
    end
  end

  def public_show
    @nav_li_active = 'explore'
    @show_response, @document = fetch(params[:id])
    @institution_title = @document[:institution_name_ssim].first

    # get the response for collection objects
    @collex_response, @collex_documents = search_results({:f => {'model_ssi' => 'Collection','institution_pid_ssi' => params[:id]},:rows => 100, :sort => 'title_info_ssort asc'})

    # add params[:f] for proper facet links
    params[:f] = {blacklight_config.institution_field => [@institution_title]}

    # get the response for the facets representing items in collection
    (@response, @document_list) = search_results({:f => params[:f]})

    respond_to do |format|
      format.html
    end

  end

  def public_index
    @nav_li_active = 'explore'
    (@response, @document_list) = search_results({:f => {'model_ssi' => 'Institution'},:rows => 100, :sort => 'title_primary_ssort asc'})
    #params[:per_page] = params[:per_page].presence || '50'
    #(@response, @document_list) = search_results(params, search_params_logic)

    params[:view] = 'list'
    params[:sort] = 'title_primary_ssort asc'

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
