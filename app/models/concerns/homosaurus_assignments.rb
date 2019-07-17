module HomosaurusAssignments
  def exactMatch_lcsh=(value)
    r = []
    values = clean_values(value)
    values.each do |val|
      if val.class == String
        ld = LcshSubject.find_by(uri: val)
        if ld.blank?
          english_label = nil
          default_label = nil
          any_match = nil
          full_alt_term_list = []

          if Repo.connection.query(:subject=>::RDF::URI.new(val), :predicate=>Repo.qskos('prefLabel')).count > 0
            # Get prefLabel
            Repo.connection.query(:subject=>::RDF::URI.new(val), :predicate=>Repo.qskos('prefLabel')).each_statement do |result_statement|
              #LoC has blank nodes... see alts of http://id.loc.gov/authorities/subjects/sh85102696 ... these aren't literals.
              #LoC's blank node representation.... alt: to_s == "_:t829213" or check .resource? or check .node? or .id == 't829213'
              if result_statement.object.literal?
                if result_statement.object.language == :en
                  english_label ||= result_statement.object.value
                elsif result_statement.object.language.blank?
                  default_label ||= result_statement.object.value
                  full_alt_term_list << result_statement.object.value
                else
                  any_match ||= result_statement.object.value
                  #FIXME
                  full_alt_term_list << result_statement.object.value
                end
              end
            end

            full_alt_term_list -= [default_label] if english_label.blank? && default_label.present?
            full_alt_term_list -= [any_match] if english_label.blank? && default_label.blank? && any_match.present?

            default_label ||= any_match
            english_label ||= default_label

            # Get alt labels
            Repo.connection.query(:subject=>::RDF::URI.new(val), :predicate=>Repo.qskos('altLabel')).each_statement do |result_statement|
              #LoC has blank nodes... see alts of http://id.loc.gov/authorities/subjects/sh85102696 ... these aren't literals.
              #LoC's blank node representation.... alt: to_s == "_:t829213" or check .resource? or check .node? or .id == 't829213'
              if result_statement.object.literal?
                full_alt_term_list << result_statement.object.value
              end
            end
            full_alt_term_list.uniq!

            #TODO: Broader? Narrower? Etc?

            ld = LcshSubject.create(uri: val, label: english_label, alt_labels: full_alt_term_list)
          else
            raise "Could not find lcsh for prefLabel for: #{val.to_s}"
          end
        end
        r << ld
        raise "Could not find lcsh for: #{val.to_s}" if r.last.nil?
      elsif val.class == LcshSubject
        r << val
      else
        raise 'Unhandled GenericObject assignment for: ' + val.class.to_s
      end
    end
    value = r
    super
  end

  def closeMatch_lcsh=(value)
    r = []
    values = clean_values(value)
    values.each do |val|
      if val.class == String
        ld = LcshSubject.find_by(uri: val)
        if ld.blank?
          english_label = nil
          default_label = nil
          any_match = nil
          full_alt_term_list = []

          if Repo.connection.query(:subject=>::RDF::URI.new(val), :predicate=>Repo.qskos('prefLabel')).count > 0
            # Get prefLabel
            Repo.connection.query(:subject=>::RDF::URI.new(val), :predicate=>Repo.qskos('prefLabel')).each_statement do |result_statement|
              #LoC has blank nodes... see alts of http://id.loc.gov/authorities/subjects/sh85102696 ... these aren't literals.
              #LoC's blank node representation.... alt: to_s == "_:t829213" or check .resource? or check .node? or .id == 't829213'
              if result_statement.object.literal?
                if result_statement.object.language == :en
                  english_label ||= result_statement.object.value
                elsif result_statement.object.language.blank?
                  default_label ||= result_statement.object.value
                  full_alt_term_list << result_statement.object.value
                else
                  any_match ||= result_statement.object.value
                  #FIXME
                  full_alt_term_list << result_statement.object.value
                end
              end
            end

            full_alt_term_list -= [default_label] if english_label.blank? && default_label.present?
            full_alt_term_list -= [any_match] if english_label.blank? && default_label.blank? && any_match.present?

            default_label ||= any_match
            english_label ||= default_label

            # Get alt labels
            Repo.connection.query(:subject=>::RDF::URI.new(val), :predicate=>Repo.qskos('altLabel')).each_statement do |result_statement|
              #LoC has blank nodes... see alts of http://id.loc.gov/authorities/subjects/sh85102696 ... these aren't literals.
              #LoC's blank node representation.... alt: to_s == "_:t829213" or check .resource? or check .node? or .id == 't829213'
              if result_statement.object.literal?
                full_alt_term_list << result_statement.object.value
              end
            end
            full_alt_term_list.uniq!

            #TODO: Broader? Narrower? Etc?

            ld = LcshSubject.create(uri: val, label: english_label, alt_labels: full_alt_term_list)
          else
            raise "Could not find lcsh for prefLabel for: #{val.to_s}"
          end
        end
        r << ld
        raise "Could not find lcsh for: #{val.to_s}" if r.last.nil?
      elsif val.class == LcshSubject
        r << val
      else
        raise 'Unhandled GenericObject assignment for: ' + val.class.to_s
      end
    end
    value = r
    super
  end
end