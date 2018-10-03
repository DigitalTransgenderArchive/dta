# frozen_string_literal: true
class CatalogController < ApplicationController
  include BlacklightRangeLimit::ControllerOverride
  include BlacklightMaps::ControllerOverride
  include DtaSearchHelper

  include Blacklight::Catalog
  include DtaStaticBuilder

  #layout "sufia-one-column"
  #layout "local_blacklight"

  before_action :get_latest_content
  #before_action :enforce_show_permissions, only: :show
  #skip_before_action :default_html_head

  #CatalogController.search_params_logic += [:add_access_controls_to_solr_params, :add_advanced_parse_q_to_solr, :exclude_unwanted_models]

  before_action  only: [:index, :facet] do
    if current_user.present? and current_user.contributor?
      blacklight_config.add_facet_field 'publisher_ssim', :label => 'Publisher', :limit => 6, :sort => 'index', :collapse => true, :show => true
      blacklight_config.add_facet_field 'visibility_ssi', :label => 'Visibility', :limit => 3, :collapse => false

      uploaded_field = 'date_uploaded_dtsi'
      modified_field = 'date_modified_dtsi'
      blacklight_config.add_sort_field "#{uploaded_field} desc", label: "date uploaded \u25BC"
      blacklight_config.add_sort_field "#{uploaded_field} asc", label: "date uploaded \u25B2"
      blacklight_config.add_sort_field "#{modified_field} desc", label: "date modified \u25BC"
      blacklight_config.add_sort_field "#{modified_field} asc", label: "date modified \u25B2"

      blacklight_config.add_sort_field 'collection_name_ssort asc, dta_sortable_date_dtsi asc', :label => "collection \u25B2"
      blacklight_config.add_sort_field 'collection_name_ssort desc, dta_sortable_date_dtsi asc', :label => "collection \u25BC"

      blacklight_config.add_sort_field 'visibility_ssi asc, dta_sortable_date_dtsi asc', :label => "visibility \u25B2"
      blacklight_config.add_sort_field 'visibility_ssi desc, dta_sortable_date_dtsi asc', :label => "visibility \u25BC"

      blacklight_config.add_index_field 'visibility_ssi', :label => 'Visbility'
    else
      blacklight_config.add_facet_field 'publisher_ssim', :label => 'Publisher', :limit => 6, :sort => 'index', :collapse => true, :show => false
    end
  end

  def has_search_parameters?
    params[:dtalimits].present? || super
  end

  configure_blacklight do |config|
    #config.add_facet_field 'publisher_ssim', :label => 'Publisher', :limit => 6, :sort => 'index', :collapse => true, :show => true

    # collection name field
    config.collection_field = 'collection_name_ssim'
    # institution name field
    config.institution_field = 'institution_name_ssim'
    # solr field for flagged/inappropriate content
    config.flagged_field = 'flagged_ssi'

    #config.view.gallery.default = true # List is now the default
    config.view.gallery.partials = [:index_header, :index]
    config.view.masonry.partials = [:index]
    config.view.slideshow.partials = [:index]

    config.show.tile_source_field = :content_metadata_image_iiif_info_ssm
    config.show.partials.insert(1, :openseadragon)

    # Show gallery view
    config.view.gallery.partials = [:index_header, :index]
    config.view.slideshow.partials = [:index]

    # blacklight-maps stuff
    config.view.maps.geojson_field = 'subject_geojson_facet_ssim'
    config.view.maps.coordinates_field = 'subject_coordinates_geospatial'
    config.view.maps.placename_field = 'subject_geographic_ssim'
    config.view.maps.maxzoom = 13
    config.view.maps.show_initial_zoom = 9
    config.view.maps.facet_mode = 'geojson'

    #set default per-page
    config.default_per_page = 15
    config.per_page = [15,25,50,100,200]

    config.max_per_page = 300

    ## Default parameters to send to solr for all search-like requests. See also SolrHelper#solr_search_params
    config.default_solr_params = {
        qt: "search",
        rows: 20
    }

    config.search_builder_class = ::DefaultSearchBuilder

    config.index.title_field = 'title_tesim'
    config.index.display_type_field = 'blacklight_display_ssi'
    config.index.thumbnail_method = :dta_thumbnail_tag

    config.add_facet_field 'dtalimits', label: "Limit", :show => false, query: {
        :ex_fa => { label: 'Exclude Finding Aids', fq: '-genre_ssim:"Finding Aids"' }
    }
    config.add_facet_field 'creator_ssim', label: "Creator", limit: 6, collapse:false
    config.add_facet_field 'dta_all_subject_ssim', :label => 'Topic', :limit => 6, :sort => 'count', :collapse => false
    config.add_facet_field 'dta_other_subject_ssim', :label => 'Subject', :limit => 6, :sort => 'count', :collapse => false
    config.add_facet_field 'dta_dates_ssim', :label => 'Date', :range => { num_segments: 6}, :collapse => false
    config.add_facet_field 'genre_ssim', :label => 'Genre', :limit => 6, :sort => 'count', :collapse => true
    config.add_facet_field 'subject_geographic_ssim', :label => 'Location', :limit => 6, :sort => 'count', :collapse => true
    config.add_facet_field 'collection_name_ssim', :label => 'Collection', :limit => 8, :sort => 'count', :collapse => true
    config.add_facet_field 'institution_name_ssim', :label => 'Institution', :limit => 8, :sort => 'count', :collapse => true
    config.add_facet_field 'subject_geojson_facet_ssim', :limit => -2, :label => 'Coordinates', :show => false

    config.add_facet_fields_to_solr_request!

    config.add_index_field 'collection_name_ssim', :label => 'Collection'
    config.add_index_field 'institution_name_ssim', :label => 'Institution'
    config.add_index_field "creator_ssim", label: "Creator", itemprop: 'creator'
    config.add_index_field 'date_created_display_ssim', :label => 'Date'
    config.add_index_field 'date_issued_display_ssim', :label => 'Date'

    config.add_search_field('all_fields') do |field|
      field.label = 'All Text'
      field.include_in_advanced_search = false
      field.solr_parameters = { :'spellcheck.dictionary' => 'default' }
    end

    config.add_search_field('title') do |field|
      #field.solr_parameters = { :'spellcheck.dictionary' => 'title' }

      #field.solr_local_parameters = {
          #qf: '$title_qf',
          #pf: '$title_pf'
      #}
      field.solr_parameters = {
          'spellcheck.dictionary': 'title',
          qf: '${title_qf}',
          pf: '${title_pf}'
      }
    end

    config.add_search_field('description') do |field|
      field.solr_parameters = {
          'spellcheck.dictionary': 'description',
          qf: '${description_qf}',
          pf: '${description_pf}'
      }
    end

    config.add_search_field('creator') do |field|
      field.solr_parameters = {
          'spellcheck.dictionary': 'creator',
          qf: '${creator_qf}',
          pf: '${creator_pf}'
      }
    end

    config.add_search_field('publisher') do |field|
      field.solr_parameters = {
          'spellcheck.dictionary': 'publisher',
          qf: '${publisher_qf}',
          pf: '${publisher_pf}'
      }
    end

    config.add_search_field('othersubject') do |field|
      #field.label = 'People / Organizations'
      field.label = 'People'

      field.solr_parameters = {
          'spellcheck.dictionary': 'othersubject',
          qf: '${othersubject_qf}',
          pf: '${othersubject_pf}'
      }
    end

    config.add_search_field('identifier') do |field|
      field.label = 'Identifier'

      field.solr_parameters = {
          'spellcheck.dictionary': 'identifier',
          qf: '${identifier_qf}',
          pf: '${identifier_pf}'
      }
    end

    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    config.add_sort_field 'score desc, title_primary_ssort asc', :label => 'relevance'
    config.add_sort_field 'title_primary_ssort asc, dta_sortable_date_dtsi asc', :label => "title \u25B2"
    config.add_sort_field 'title_primary_ssort desc, dta_sortable_date_dtsi asc', :label => "title \u25BC"
    config.add_sort_field 'dta_sortable_date_dtsi asc, title_primary_ssort asc', :label => "date \u25B2"
    config.add_sort_field 'dta_sortable_date_dtsi desc, title_primary_ssort asc', :label => "date \u25BC"

    # If there are more than this many search results, no spelling ("did you
    # mean") suggestion is offered.
    config.spell_max = 10

    # Configuration for autocomplete suggestor
    config.autocomplete_enabled = true
    config.autocomplete_path = 'suggest'
  end

  # displays values and pagination links for Format field
  def genre_facet
    @nav_li_active = 'explore'
    @facet_no_more_link = true

    @facet = blacklight_config.facet_fields['genre_ssim']
    @response = get_facet_field_response(@facet.key, params)
    @display_facet = @response.aggregations[@facet.key]

    @pagination = facet_paginator(@facet, @display_facet)

    render :full_browse_facet
  end

  def topic_facet
    @nav_li_active = 'explore'
    @facet_no_more_link = true

    @facet = blacklight_config.facet_fields['dta_all_subject_ssim']
    @response = get_facet_field_response(@facet.key, params)
    @display_facet = @response.aggregations[@facet.key]

    @pagination = facet_paginator(@facet, @display_facet)

    render :full_browse_facet
  end
end
