class GeoLookupInput < MeiMultiLookupInput

  def buffer_each(collection)
    collection.each_with_object('').with_index do |(value, buffer), index|
      #buffer << yield(value, index) if value.match(/http:\/\/id.loc.gov\/authorities\/subjects\//) || value.blank?
      if  value.blank? and !@rendered_first_element
        buffer << yield(value, index)
      elsif value.present?
        r = RestClient.get 'http://api.geonames.org/getJSON', {:params => {:geonameId=>"#{value.split('/').last}", :username=>"boston_library"}, accept: :json}
        result = JSON.parse(r)

        buffer << yield("#{result['name']} (#{value})", index)
      end
    end
  end

end
