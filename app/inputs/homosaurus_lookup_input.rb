class HomosaurusLookupInput < MeiMultiLookupInput

  def buffer_each(collection)
    collection.each_with_object('').with_index do |(value, buffer), index|
      #buffer << yield(value, index) if value.match(/http:\/\/homosaurus\.org\/terms\//) || value.blank?
      if value.blank? and !@rendered_first_element
        buffer << yield(value, index)
      elsif value.match(/http:\/\/homosaurus\.org\/terms\//)
        term = Homosaurus.find('homosaurus/terms/' + value.split('/').last)
        buffer << yield("#{term.prefLabel} (#{value})", index)
      end
    end
  end

end
