class HomosaurusAutocomplete

  def self.find(subject)
    matches = []
    dup_checker = []
    subject = subject.downcase #FIXME?

    solr_response = DSolr.find({q: "dta_homosaurus_lcase_prefLabel_ssi:*#{solr_clean(subject)}* AND model_ssi:Homosaurus", rows: '25', fl: 'identifier_ssi, prefLabel_ssim, altLabel_ssim, narrower_ssim, broader_ssim, related_ssim' })

    #FIXME - A result for "http" gives back the entire array of values...
    if solr_response.present?

      solr_response.each do |indv_response|
        indv_subj = indv_response["identifier_ssi"]
        if dup_checker.length < 20 && !dup_checker.include?(indv_subj)
          matches << indv_response
          dup_checker << indv_subj
        end
      end
    end


    if dup_checker.length < 20
      solr_response = DSolr.find({q: "dta_homosaurus_lcase_altLabel_ssim:*#{solr_clean(subject)}* AND model_ssi:Homosaurus", rows: '25', fl: 'identifier_ssi, prefLabel_ssim, altLabel_ssim, narrower_ssim, broader_ssim, related_ssim' })

      #FIXME - A result for "http" gives back the entire array of values...
      if solr_response.present?

        solr_response.each do |indv_response|
          indv_subj = indv_response["identifier_ssi"]
          if dup_checker.length < 20 && !dup_checker.include?(indv_subj)
            matches << indv_response
            dup_checker << indv_subj
          end
        end
      end
    end

    if dup_checker.length < 20
      solr_response = DSolr.find({q: "dta_homosaurus_lcase_comment_tesi:#{solr_clean(subject)} AND model_ssi:Homosaurus", rows: '25', fl: 'identifier_ssi, prefLabel_ssim, altLabel_ssim, comment_ssim, narrower_ssim, broader_ssim, related_ssim' })

      #FIXME - A result for "http" gives back the entire array of values...
      if solr_response.present?

        solr_response.each do |indv_response|
          indv_subj = indv_response["identifier_ssi"]
          if dup_checker.length < 20 && !dup_checker.include?(indv_subj)
            matches << indv_response
            dup_checker << indv_subj
          end
        end
      end
    end

    if matches.present?

      return matches.map! { |item|
        ##{URI.escape(item)}
        full_uri = 'http://homosaurus.org/terms/' + item['identifier_ssi']

        count = DSolr.find({q: "homosaurus_subject_ssim:#{solr_clean(full_uri)}", rows: '100', fl: 'subject_tesim' }).length
        if count >= 99
          count = "99+"
        else
          count = count.to_s
        end

        variants = item['altLabel_ssim']

        {
            "uri_link" => full_uri,
            "label" => item['prefLabel_ssim'].first,
            "broader" => getBroader(item['broader_ssim']),
            "narrower" => getNarrower(item['narrower_ssim']),
            "related" => getRelated(item['related_ssim']),
            "variants" => variants,
            "count" => count
        }
      }
    else
      return []
    end
  end

  def self.getBroader(broader_uris)
    broader_list = []

    if broader_uris.present?
      broader_uris.each do |broader_single_uri|
        broader_label = DSolr.find({q: "id:#{solr_clean("homosaurus/terms/#{broader_single_uri}")} AND model_ssi:Homosaurus", rows: '1', fl: 'prefLabel_ssim' })
        broader_list << {:uri_link=>"http://homosaurus.org/terms/#{broader_single_uri.split('/').last}", :label=>broader_label[0]["prefLabel_ssim"][0]}
      end
    end

    return broader_list
  end

  def self.getNarrower(narrower_uris)
    narrower_list = []

    if narrower_uris.present?
      narrower_uris.each do |narrower_single_uri|
        narrower_label = DSolr.find({q: "id:#{solr_clean("homosaurus/terms/#{narrower_single_uri}")} AND model_ssi:Homosaurus", rows: '1', fl: 'prefLabel_ssim' })
        narrower_list << {:uri_link=>"http://homosaurus.org/terms/#{narrower_single_uri.split('/').last}", :label=>narrower_label[0]["prefLabel_ssim"][0]}
      end
    end

    return narrower_list
  end

  def self.getRelated(related_uris)
    related_list = []

    if related_uris.present?
      related_uris.each do |related_single_uri|
        related_label = DSolr.find({q: "id:#{solr_clean("homosaurus/terms/#{related_single_uri}")} AND model_ssi:Homosaurus", rows: '1', fl: 'prefLabel_ssim' })
        related_list << {:uri_link=>"http://homosaurus.org/terms/#{related_single_uri.split('/').last}", :label=>related_label[0]["prefLabel_ssim"][0]}
      end
    end

    return related_list
  end

  def self.solr_clean(term)
    return term.gsub('\\', '\\\\').gsub(':', '\\:').gsub(' ', '\ ')
  end

end
