# frozen_string_literal: true
  class DefaultSearchBuilder < Blacklight::SearchBuilder
    include Blacklight::Solr::SearchBuilderBehavior
    include BlacklightRangeLimit::RangeLimitBuilder
    include BlacklightAdvancedSearch::AdvancedSearchBuilder
    include CommonSearchBuilder
    self.default_processor_chain += [:add_advanced_search_to_solr, :exclude_unwanted_models, :set_visibility]

    def exclude_unwanted_models(solr_parameters = {}, otherval=nil)
      solr_parameters[:fq] ||= []
      solr_parameters[:fq] << "-model_ssi:\"Institution\""
      solr_parameters[:fq] << "-model_ssi:\"Collection\""
      solr_parameters[:fq] << "-model_ssi:\"Homosaurus\""
      solr_parameters[:fq] << "-model_ssi:\"HomosaurusV2\""
    end

    ##
    # @example Adding a new step to the processor chain
    #   self.default_processor_chain += [:add_custom_data_to_query]
    #
    #   def add_custom_data_to_query(solr_parameters)
    #     solr_parameters[:custom] = blacklight_params[:user_value]
    #   end
end
