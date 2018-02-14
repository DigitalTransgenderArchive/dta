module DtaSearchBuilder

# used by InstitutionsController#index
  def institutions_filter(solr_parameters = {}, wtf=nil)
    solr_parameters[:fq] = []
    solr_parameters[:fq] << "+active_fedora_model_ssi:\"Institution\""
  end

# used by CollectionsController#public_index
  def collections_filter(solr_parameters = {}, wtf=nil)
    solr_parameters[:fq] = []
    solr_parameters[:fq] << "+active_fedora_model_ssi:\"Collection\""
    solr_parameters[:fq] << "+is_public_ssi:\"true\""
  end

  def flagged_filter(solr_parameters = {}, wtf=nil)
    solr_parameters[:fq] << "-flagged_tesim:\"Explicit content in thumbnail\""
  end
end
