# frozen_string_literal: true
  class CollectionSearchBuilder < Blacklight::SearchBuilder
    include Blacklight::Solr::SearchBuilderBehavior
    include BlacklightRangeLimit::RangeLimitBuilder
    include BlacklightAdvancedSearch::AdvancedSearchBuilder
    include CommonSearchBuilder
    self.default_processor_chain += [:collections_only, :set_visibility]

    def collections_only(solr_parameters = {}, other_param=nil)
      solr_parameters[:fq] ||= []
      solr_parameters[:fq] << "+model_ssi:\"Collection\""
    end

    ##
    # @example Adding a new step to the processor chain
    #   self.default_processor_chain += [:add_custom_data_to_query]
    #
    #   def add_custom_data_to_query(solr_parameters)
    #     solr_parameters[:custom] = blacklight_params[:user_value]
    #   end
end
