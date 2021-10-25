class HomosaurusV3Controller < ApplicationController
  before_action :verify_homosaurus
  include DtaStaticBuilder

  def index
    #@terms = HomosaurusV3.all.sort_by { |term| term.preferred_label }
    #@terms = HomosaurusV3.all
    @terms = HomosaurusV3Subject.find_with_conditions(q: "*:*", rows: '10000', fl: 'id,prefLabel_tesim,identifier_ssi' )
    @terms = @terms.sort_by { |term| term["prefLabel_tesim"].first.downcase }
  end

  def show
    is_id = Integer(params[:id]) rescue false
    if is_id
      @homosaurus = HomosaurusV3Subject.find(params[:id])
    else
      @homosaurus = HomosaurusV3Subject.find_by(identifier: params[:id].to_s)
    end
    @homosaurus_solr = DSolr.find_by_id('homosaurus/v3/' + @homosaurus.identifier)



    respond_to do |format|
      format.html
      #format.nt { render body: @homosaurus.full_graph.dump(:ntriples), :content_type => Mime::NT }
      #format.jsonld { render body: @homosaurus.full_graph.dump(:jsonld, standard_prefixes: true), :content_type => Mime::JSONLD }
    end
  end

  def new
    @homosaurus = HomosaurusV3Subject.new
    term_query = HomosaurusV3Subject.find_with_conditions(q: "*:*", rows: '10000', fl: 'id,identifier_ssi' )
    term_query = term_query.sort_by { |term| term["identifier_ssi"].downcase }
    @all_terms = []
    term_query.each { |term| @all_terms << [term["identifier_ssi"], term["identifier_ssi"]] }

  end

  def create
    ActiveRecord::Base.transaction do
      @homosaurus = HomosaurusV3Subject.new
      # Fix the below
      numeric_identifier = HomosaurusV3Subject.mint
      identifier = "homoit" + numeric_identifier.to_s.rjust(7, '0')

      @homosaurus.numeric_pid = numeric_identifier
      @homosaurus.identifier = identifier
      @homosaurus.pid = "homosaurus/v3/#{identifier}"
      @homosaurus.uri = "https://homosaurus.org/v3/#{identifier}"
      @homosaurus.version = "v3"

      @homosaurus.update(homosaurus_params)

      @homosaurus.save

      if params[:homosaurus][:broader].present?
        params[:homosaurus][:broader].each do |broader|
          if broader.present?
            broader_object = HomosaurusV3Subject.find_by(identifier: broader)
            @homosaurus.broader = @homosaurus.broader + [broader_object.identifier]
            broader_object.narrower = broader_object.narrower + [@homosaurus.identifier]
            broader_object.save
          end
        end
      end

      if params[:homosaurus][:narrower].present?
        params[:homosaurus][:narrower].each do |narrower|
          if narrower.present?
            narrower_object = HomosaurusV3Subject.find_by(identifier: narrower)
            @homosaurus.narrower = @homosaurus.narrower + [narrower_object.identifier]
            narrower_object.broader = narrower_object.broader + [@homosaurus.identifier]
            narrower_object.save
          end

        end
      end

      if params[:homosaurus][:related].present?
        params[:homosaurus][:related].each do |related|
          if related.present?
            related_object = HomosaurusV3Subject.find_by(identifier: related)
            @homosaurus.related = @homosaurus.related + [related_object.identifier]
            related_object.related = related_object.related + [@homosaurus.identifier]
            related_object.save
          end

        end
      end

      if @homosaurus.save
        redirect_to homosaurus_v3_path(:id => @homosaurus.id)
      else
        redirect_to new_homosaurus_v3_path
      end
    end
  end

  def edit
    @homosaurus = HomosaurusV3Subject.find(params[:id])
    term_query = HomosaurusV3Subject.find_with_conditions(q: "*:*", rows: '100000', fl: 'id,identifier_ssi' )
    term_query = term_query.sort_by { |term| term["identifier_ssi"].downcase }
    @all_terms = []
    term_query.each { |term|
      if @homosaurus.identifier != term["id"]
        @all_terms << [term["identifier_ssi"], term["identifier_ssi"]]
        #@all_terms << term["identifier_ssi"]
      end
    }
  end

  def set_match_relationship(form_fields, key)
    form_fields[key.to_sym].each_with_index do |s, index|
      if s.present?
        form_fields[key.to_sym][index] = s.split('(').last
        form_fields[key.to_sym][index].gsub!(/\)$/, '')
      end
    end
    if form_fields[key.to_sym][0].present?
      @homosaurus.send("#{key}=", form_fields[key.to_sym].reject { |c| c.empty? })
    elsif @homosaurus.send(key).present?
      @homosaurus.send("#{key}=", [])
    end
  end

  def update
    if !params[:homosaurus][:identifier].match(/^[0-9a-zA-Z_\-+]+$/) || params[:homosaurus][:identifier].match(/ /)
      redirect_to homosaurus_v3_path(:id => params[:id]), notice: "Please use camel case for identifier like 'discrimationWithAbleism'... do not use spaces. Contact K.J. if this is seen for some other valid entry."
    else
      ActiveRecord::Base.transaction do
        @homosaurus = HomosaurusV3Subject.find(params[:id])

        pid = "homosaurus/v3/#{params[:homosaurus][:identifier]}"
        pid_original = @homosaurus.pid

        #FIXME: Only do this if changed...
        @homosaurus.broader.each do |broader|
          hier_object = HomosaurusV3Subject.find_by(identifier: broader)
          hier_object.narrower.delete(@homosaurus.identifier)
          hier_object.save
        end


        @homosaurus.narrower.each do |narrower|
          hier_object = HomosaurusV3Subject.find_by(identifier: narrower)
          hier_object.broader.delete(@homosaurus.identifier)
          hier_object.save
        end


        @homosaurus.related.each do |related|
          hier_object = HomosaurusV3Subject.find_by(identifier: related)
          hier_object.related.delete(@homosaurus.identifier)
          hier_object.save
        end
        @homosaurus.reload

        @homosaurus.broader = []
        @homosaurus.narrower = []
        @homosaurus.related = []

        @homosaurus.pid = pid
        @homosaurus.uri = "https://homosaurus.org/v3/#{params[:homosaurus][:identifier]}"
        @homosaurus.identifier = params[:homosaurus][:identifier]

        set_match_relationship(params[:homosaurus], "exactMatch_lcsh")
        set_match_relationship(params[:homosaurus], "closeMatch_lcsh")

        @homosaurus.update(homosaurus_params)

        @homosaurus.save

        if params[:homosaurus][:broader].present?
          params[:homosaurus][:broader].each do |broader|
            if broader.present?
              broader_object = HomosaurusV3Subject.find_by(identifier: broader)
              @homosaurus.broader = @homosaurus.broader + [broader_object.identifier]
              broader_object.narrower = broader_object.narrower + [@homosaurus.identifier]
              broader_object.save
            end
          end
        end

        if params[:homosaurus][:narrower].present?
          params[:homosaurus][:narrower].each do |narrower|
            if narrower.present?
              narrower_object = HomosaurusV3Subject.find_by(identifier: narrower)
              @homosaurus.narrower = @homosaurus.narrower + [narrower_object.identifier]
              narrower_object.broader = narrower_object.broader + [@homosaurus.identifier]
              narrower_object.save
            end

          end
        end

        if params[:homosaurus][:related].present?
          params[:homosaurus][:related].each do |related|
            if related.present?
              related_object = HomosaurusV3Subject.find_by(identifier: related)
              @homosaurus.related = @homosaurus.related + [related_object.identifier]
              related_object.related = related_object.related + [@homosaurus.identifier]
              related_object.save
            end

          end
        end


        if @homosaurus.save
          #flash[:success] = "HomosaurusV3 term was updated!"
          if pid != pid_original
            DSolr.delete_by_id(pid_original)
          end
          redirect_to homosaurus_v3_path(:id => @homosaurus.id), notice: "HomosaurusV3 term was updated!"
        else
          redirect_to homosaurus_v3_path(:id => @homosaurus.id), notice: "Failure! Term was not updated."
        end
      end
    end
  end

  def destroy

    @homosaurus = HomosaurusV3Subject.find(params[:id])

    @homosaurus.broader.each do |broader|
      hier_object = HomosaurusV3Subject.find_by(identifier: broader)
      hier_object.narrower.delete(@homosaurus.identifier)
      hier_object.save
    end


    @homosaurus.narrower.each do |narrower|
      hier_object = HomosaurusV3Subject.find_by(identifier: narrower)
      hier_object.broader.delete(@homosaurus.identifier)
      hier_object.save
    end


    @homosaurus.related.each do |related|
      hier_object = HomosaurusV3Subject.find_by(identifier: related)
      hier_object.related.delete(@homosaurus.identifier)
      hier_object.save
    end
    @homosaurus.reload

    @homosaurus.broader = []
    @homosaurus.narrower = []
    @homosaurus.related = []

    @homosaurus.destroy
    redirect_to homosaurus_v3_index_path, notice: "HomosaurusV3 term was deleted!"
  end


  def homosaurus_params
       params.require(:homosaurus).permit(:identifier, :label, :label_eng, :description, :exactMatch, :closeMatch, alt_labels: [])
  end
end