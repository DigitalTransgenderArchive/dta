class MltSearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior
  include BlacklightRangeLimit::RangeLimitBuilder
  include BlacklightAdvancedSearch::AdvancedSearchBuilder
  include CommonSearchBuilder
  self.default_processor_chain += [:add_advanced_search_to_solr, :exclude_unwanted_models, :set_visibility, :mlt_params]

  def exclude_unwanted_models(solr_parameters = {}, otherval=nil)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << "-model_ssi:\"Institution\""
    solr_parameters[:fq] << "-model_ssi:\"Collection\""
    solr_parameters[:fq] << "-model_ssi:\"Homosaurus\""
  end

  # for 'more like this' search -- set solr id param to params[:mlt_id]
  def mlt_params(solr_parameters = {})
    solr_parameters[:id] = blacklight_params[:mlt_id]
    solr_parameters[:qt] = 'mlt'
    solr_parameters[:mlt] = true
    #solr_parameters[:'mlt.fl'] = 'subject_facet_ssim,subject_geo_city_ssim,related_item_host_ssim'
    solr_parameters[:'mlt.fl'] = 'homosaurus_subject_ssim,lcsh_subject_ssim,other_subject_ssim,collection_name_ssim,based_near_ssim'
    solr_parameters[:'mlt.match.include'] = false
    solr_parameters[:'mlt.mintf'] = 1
    #solr_parameters[:'mlt.qf'] = 'subject_facet_ssim^10 subject_geo_city_ssim^5 related_item_host_ssim'
    solr_parameters[:'mlt.qf'] = 'homosaurus_subject_ssim^6 lcsh_subject_ssim^3 other_subject_ssim^3 collection_name_ssim based_near_ssim'

    # I added based on: https://issues.apache.org/jira/browse/SOLR-7883
    solr_parameters[:facet] = false
  end

end
