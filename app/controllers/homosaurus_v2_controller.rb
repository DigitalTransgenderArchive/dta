class HomosaurusV2Controller < ApplicationController
  before_action :verify_homosaurus
  include DtaStaticBuilder

  def index
    #@terms = HomosaurusV2.all.sort_by { |term| term.preferred_label }
    #@terms = HomosaurusV2.all
    @terms = HomosaurusV2Subject.find_with_conditions(q: "*:*", rows: '10000', fl: 'id,prefLabel_tesim,identifier_ssi' )
    @terms = @terms.sort_by { |term| term["prefLabel_tesim"].first.downcase }
  end

  def show
    is_id = Integer(params[:id]) rescue false
    if is_id
      @homosaurus = HomosaurusV2Subject.find(params[:id])
    else
      @homosaurus = HomosaurusV2Subject.find_by(identifier: params[:id].to_s)
    end
    @homosaurus_solr = DSolr.find_by_id('homosaurus/v2/' + @homosaurus.identifier)



    respond_to do |format|
      format.html
      #format.nt { render body: @homosaurus.full_graph.dump(:ntriples), :content_type => Mime::NT }
      #format.jsonld { render body: @homosaurus.full_graph.dump(:jsonld, standard_prefixes: true), :content_type => Mime::JSONLD }
    end
  end

  def new
    @homosaurus = HomosaurusV2Subject.new
    term_query = HomosaurusV2Subject.find_with_conditions(q: "*:*", rows: '10000', fl: 'id,identifier_ssi' )
    term_query = term_query.sort_by { |term| term["identifier_ssi"].downcase }
    @all_terms = []
    term_query.each { |term| @all_terms << [term["identifier_ssi"], term["identifier_ssi"]] }

  end

  def create
    if !params[:homosaurus][:identifier].match(/^[0-9a-zA-Z_\-+]+$/) || params[:homosaurus][:identifier].match(/ /)
      redirect_to new_homosaurus_v2_path, notice: "Please use camel case for identifier like 'discrimationWithAbleism'... do not use spaces. Contact K.J. if this is seen for some other valid entry."
    else

      ActiveRecord::Base.transaction do
        @homosaurus = HomosaurusV2Subject.new

        @homosaurus.pid = "homosaurus/v2/#{params[:homosaurus][:identifier]}"
        @homosaurus.uri = "http://homosaurus.org/v2/#{params[:homosaurus][:identifier]}"
        @homosaurus.version = "v2"

        @homosaurus.update(homosaurus_params)

        @homosaurus.save

        if params[:homosaurus][:broader].present?
          params[:homosaurus][:broader].each do |broader|
            if broader.present?
              broader_object = HomosaurusV2Subject.find_by(identifier: broader)
              @homosaurus.broader = @homosaurus.broader + [broader_object.identifier]
              broader_object.narrower = broader_object.narrower + [@homosaurus.identifier]
              broader_object.save
            end
          end
        end

        if params[:homosaurus][:narrower].present?
          params[:homosaurus][:narrower].each do |narrower|
            if narrower.present?
              narrower_object = HomosaurusV2Subject.find_by(identifier: narrower)
              @homosaurus.narrower = @homosaurus.narrower + [narrower_object.identifier]
              narrower_object.broader = narrower_object.broader + [@homosaurus.identifier]
              narrower_object.save
            end

          end
        end

        if params[:homosaurus][:related].present?
          params[:homosaurus][:related].each do |related|
            if related.present?
              related_object = HomosaurusV2Subject.find_by(identifier: related)
              @homosaurus.related = @homosaurus.related + [related_object.identifier]
              related_object.related = related_object.related + [@homosaurus.identifier]
              related_object.save
            end

          end
        end

        if @homosaurus.save
          redirect_to homosaurus_v2_path(:id => @homosaurus.id)
        else
          redirect_to new_homosaurus_v2_path
        end
      end
    end
  end

  def edit
    @homosaurus = HomosaurusV2Subject.find(params[:id])
    term_query = HomosaurusV2Subject.find_with_conditions(q: "*:*", rows: '100000', fl: 'id,identifier_ssi' )
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
      redirect_to homosaurus_v2_path(:id => params[:id]), notice: "Please use camel case for identifier like 'discrimationWithAbleism'... do not use spaces. Contact K.J. if this is seen for some other valid entry."
    else
      ActiveRecord::Base.transaction do
        @homosaurus = HomosaurusV2Subject.find(params[:id])

        pid = "homosaurus/v2/#{params[:homosaurus][:identifier]}"
        pid_original = @homosaurus.pid

        #FIXME: Only do this if changed...
        @homosaurus.broader.each do |broader|
          hier_object = HomosaurusV2Subject.find_by(identifier: broader)
          hier_object.narrower.delete(@homosaurus.identifier)
          hier_object.save
        end


        @homosaurus.narrower.each do |narrower|
          hier_object = HomosaurusV2Subject.find_by(identifier: narrower)
          hier_object.broader.delete(@homosaurus.identifier)
          hier_object.save
        end


        @homosaurus.related.each do |related|
          hier_object = HomosaurusV2Subject.find_by(identifier: related)
          hier_object.related.delete(@homosaurus.identifier)
          hier_object.save
        end
        @homosaurus.reload

        @homosaurus.broader = []
        @homosaurus.narrower = []
        @homosaurus.related = []

        @homosaurus.pid = pid
        @homosaurus.uri = "http://homosaurus.org/v2/#{params[:homosaurus][:identifier]}"
        @homosaurus.identifier = params[:homosaurus][:identifier]

        set_match_relationship(params[:homosaurus], "exactMatch_homosaurus")
        set_match_relationship(params[:homosaurus], "closeMatch_homosaurus")
        set_match_relationship(params[:homosaurus], "exactMatch_lcsh")
        set_match_relationship(params[:homosaurus], "closeMatch_lcsh")

        @homosaurus.update(homosaurus_params)

        @homosaurus.save

        if params[:homosaurus][:broader].present?
          params[:homosaurus][:broader].each do |broader|
            if broader.present?
              broader_object = HomosaurusV2Subject.find_by(identifier: broader)
              @homosaurus.broader = @homosaurus.broader + [broader_object.identifier]
              broader_object.narrower = broader_object.narrower + [@homosaurus.identifier]
              broader_object.save
            end
          end
        end

        if params[:homosaurus][:narrower].present?
          params[:homosaurus][:narrower].each do |narrower|
            if narrower.present?
              narrower_object = HomosaurusV2Subject.find_by(identifier: narrower)
              @homosaurus.narrower = @homosaurus.narrower + [narrower_object.identifier]
              narrower_object.broader = narrower_object.broader + [@homosaurus.identifier]
              narrower_object.save
            end

          end
        end

        if params[:homosaurus][:related].present?
          params[:homosaurus][:related].each do |related|
            if related.present?
              related_object = HomosaurusV2Subject.find_by(identifier: related)
              @homosaurus.related = @homosaurus.related + [related_object.identifier]
              related_object.related = related_object.related + [@homosaurus.identifier]
              related_object.save
            end

          end
        end


        if @homosaurus.save
          #flash[:success] = "HomosaurusV2 term was updated!"
          if pid != pid_original
            DSolr.delete_by_id(pid_original)
          end
          redirect_to homosaurus_v2_path(:id => @homosaurus.id), notice: "HomosaurusV2 term was updated!"
        else
          redirect_to homosaurus_v2_path(:id => @homosaurus.id), notice: "Failure! Term was not updated."
        end
      end
    end
  end

  def destroy

    @homosaurus = HomosaurusV2Subject.find(params[:id])

    @homosaurus.broader.each do |broader|
      hier_object = HomosaurusV2Subject.find_by(identifier: broader)
      hier_object.narrower.delete(@homosaurus.identifier)
      hier_object.save
    end


    @homosaurus.narrower.each do |narrower|
      hier_object = HomosaurusV2Subject.find_by(identifier: narrower)
      hier_object.broader.delete(@homosaurus.identifier)
      hier_object.save
    end


    @homosaurus.related.each do |related|
      hier_object = HomosaurusV2Subject.find_by(identifier: related)
      hier_object.related.delete(@homosaurus.identifier)
      hier_object.save
    end
    @homosaurus.reload

    @homosaurus.broader = []
    @homosaurus.narrower = []
    @homosaurus.related = []

    @homosaurus.destroy
    redirect_to homosaurus_v2_index_path, notice: "HomosaurusV2 term was deleted!"
  end


  def homosaurus_params
       params.require(:homosaurus).permit(:identifier, :label, :label_eng, :description, :exactMatch, :closeMatch, alt_labels: [])
  end
end