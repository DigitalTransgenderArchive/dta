class LcshLookupInput < MeiMultiLookupInput

  def buffer_each(collection)
    collection.each_with_object('').with_index do |(value, buffer), index|
      #buffer << yield(value, index) if value.match(/http:\/\/id.loc.gov\/authorities\/subjects\//) || value.blank?
      if  value.blank? and !@rendered_first_element
        buffer << yield(value, index)
      elsif value.match(/http:\/\/id.loc.gov\/authorities\/subjects\//)
        english_label = nil
        default_label = nil
        any_match = nil

        if GenericFile.repo.query(:subject=>::RDF::URI.new(value), :predicate=>GenericFile.qskos('prefLabel')).count > 0
          GenericFile.repo.query(:subject=>::RDF::URI.new(value), :predicate=>GenericFile.qskos('prefLabel')).each_statement do |result_statement|
            #LoC has blank nodes... see alts of http://id.loc.gov/authorities/subjects/sh85102696 ... these aren't literals.
            #LoC's blank node representation.... alt: to_s == "_:t829213" or check .resource? or check .node? or .id == 't829213'
            if result_statement.object.literal?
              if result_statement.object.language == :en
                english_label ||= result_statement.object.value
              elsif result_statement.object.language.blank?
                default_label ||= result_statement.object.value
              else
                any_match ||= result_statement.object.value
              end
            end
          end

          default_label ||= any_match
          english_label ||= default_label

          buffer << yield("#{english_label} (#{value})", index)
        end
      end
    end
  end

end
