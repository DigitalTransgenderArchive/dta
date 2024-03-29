class HomosaurusV2LookupInput < MeiMultiLookupInput

  def buffer_each(collection)
    collection.each_with_object('').with_index do |(value, buffer), index|
      #buffer << yield(value, index) if value.match(/http:\/\/homosaurus\.org\/terms\//) || value.blank?
      #if value.uri.match(/http:\/\/homosaurus\.org\/terms\//)
      if value.blank? and !@rendered_first_element
        buffer << yield(value, index)
      elsif value.present? && value.respond_to?(:uri)
        buffer << yield("#{value.label} (#{value.uri})", index)
      elsif value.present?
        h = HomosaurusV2Subject.find_by(uri: value)
        buffer << yield("#{h.label} (#{h.uri})", index)
      end
    end
  end

end
