# frozen_string_literal: true
  class DefaultSearchBuilder < Blacklight::SearchBuilder
    include Blacklight::Solr::SearchBuilderBehavior
    include BlacklightRangeLimit::RangeLimitBuilder
    include BlacklightAdvancedSearch::AdvancedSearchBuilder
    #self.default_processor_chain += [:add_advanced_parse_q_to_solr, :add_advanced_search_to_solr, :exclude_unwanted_models]
    self.default_processor_chain += [:add_advanced_search_to_solr, :exclude_unwanted_models]

    def exclude_unwanted_models(solr_parameters = {}, wtf=nil)
      solr_parameters[:fq] ||= []
      solr_parameters[:fq] << "-active_fedora_model_ssi:\"Institution\""
      solr_parameters[:fq] << "-active_fedora_model_ssi:\"Collection\""
    end


    ##
    # @example Adding a new step to the processor chain
    #   self.default_processor_chain += [:add_custom_data_to_query]
    #
    #   def add_custom_data_to_query(solr_parameters)
    #     solr_parameters[:custom] = blacklight_params[:user_value]
    #   end
end
