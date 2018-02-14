# frozen_string_literal: true
class CatalogController < ApplicationController
  include BlacklightRangeLimit::ControllerOverride
  include DtaSearchHelper

  include Blacklight::Catalog
  include DtaSearchBuilder
  include DtaStaticBuilder

  #layout "sufia-one-column"
  #layout "local_blacklight"

  #before_action :get_latest_content
  #before_action :enforce_show_permissions, only: :show
  #skip_before_action :default_html_head

  #CatalogController.search_params_logic += [:add_access_controls_to_solr_params, :add_advanced_parse_q_to_solr, :exclude_unwanted_models]

  configure_blacklight do |config|
    # collection name field
    config.collection_field = 'collection_name_ssim'
    # institution name field
    config.institution_field = 'institution_name_ssim'
    # solr field for flagged/inappropriate content
    config.flagged_field = 'flagged_ssi'

    config.view.gallery.default = true
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
    config.default_per_page = 20

    config.max_per_page = 300

    ## Default parameters to send to solr for all search-like requests. See also SolrHelper#solr_search_params
    config.default_solr_params = {
        qt: "search",
        rows: 20
    }

    config.search_builder_class = ::DefaultSearchBuilder

    config.index.title_field = 'title_tesim'
    config.index.display_type_field = 'has_model_ssim'
    config.index.thumbnail_field = :dta_thumbnail_tag

    config.add_facet_field 'dtalimits', label: "Limit", :show => false, query: {
        :ex_fa => { label: 'Exclude Finding Aids', fq: '-genre_ssim:"Finding Aids"' }
    }
    config.add_facet_field 'creator_ssim', label: "Creator", limit: 6, collapse:false
    config.add_facet_field 'dta_all_subject_ssim', :label => 'Topic', :limit => 6, :sort => 'count', :collapse => false
    config.add_facet_field 'dta_other_subject_ssim', :label => 'Subject', :limit => 6, :sort => 'count', :collapse => false
    config.add_facet_field 'dta_dates_ssim', :label => 'Date', :range => true, :collapse => false
    config.add_facet_field 'genre_ssim', :label => 'Genre', :limit => 6, :sort => 'count', :collapse => true
    config.add_facet_field 'subject_geographic_ssim', :label => 'Location', :limit => 6, :sort => 'count', :collapse => true
    config.add_facet_field 'publisher_ssim', :label => 'Publisher', :limit => 6, :sort => 'index', :collapse => true, :show => false
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
      field.solr_parameters = { :'spellcheck.dictionary' => 'description' }

      field.solr_local_parameters = {
          qf: '$description_qf',
          pf: '$description_pf'
      }
    end

    config.add_search_field('creator') do |field|
      field.solr_parameters = { :'spellcheck.dictionary' => 'creator' }

      field.solr_local_parameters = {
          qf: '$creator_qf',
          pf: '$creator_pf'
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

  def collection_base_blacklight_config
    @skip_dta_limits_render = true
    blacklight_config.facet_fields['collection_name_ssim'].show = false
    blacklight_config.facet_fields['collection_name_ssim'].if = false


=begin
    blacklight_config.facet_fields['institution_name_ssim'].show = true
    blacklight_config.facet_fields['institution_name_ssim'].if = true
    blacklight_config.facet_fields['institution_name_ssim'].collapse = false
=end


    blacklight_config.facet_fields['institution_name_ssim'].show = false
    blacklight_config.facet_fields['institution_name_ssim'].if = false


    #Needs to be fixed...
    blacklight_config.facet_fields['dta_dates_ssim'].show = false
    blacklight_config.facet_fields['dta_dates_ssim'].if = false
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
