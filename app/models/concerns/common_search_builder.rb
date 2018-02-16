module CommonSearchBuilder
  def set_visibility(solr_parameters = {}, otherval=nil)
    solr_parameters[:fq] ||= []
    if current_user.present? and current_user.contributor?
      # No limits
    else
      solr_parameters[:fq] << "+visibility_ssi:\"public\""
    end
  end
end
