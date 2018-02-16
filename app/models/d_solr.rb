class DSolr
  def self.find_by_id(id)
    solr = RSolr.connect :url => Settings.solr_url
    response = solr.get 'select', :params => {:q => "id:#{id}"}
    # result["response"]["docs"][0]["visibility_ssi"]
    response["response"]["docs"][0]
  end

  def self.find(args)
    solr = RSolr.connect :url => Settings.solr_url
    response = solr.get 'select', :params => {:q => args}
    response["response"]["docs"]
  end

  def self.delete_by_id(id)
    solr = RSolr.connect :url => Settings.solr_url, update_format: :json
    #solr.delete_by_id "#{id}"
  end

  def self.put(doc)
    raise 'No valid :id found' if doc.blank? || doc[:id].blank? || !doc[:id].match(/.....+/)
    solr = RSolr.connect :url => Settings.solr_url, update_format: :json
    solr.add [doc]
    #solr.update data: '<commit/>', headers: { 'Content-Type' => 'text/xml' }
  end

end
