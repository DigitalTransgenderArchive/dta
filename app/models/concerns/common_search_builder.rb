module CommonSearchBuilder
  def set_visibility(solr_parameters = {}, otherval=nil)
    solr_parameters[:fq] ||= []
    if scope.current_user.present? and scope.current_user.contributor?
      # No limits
    else
      solr_parameters[:fq] << "-visibility_ssi:\"private\""
      solr_parameters[:fq] << "-visibility_ssi:\"hidden\""
    end
  end
end
