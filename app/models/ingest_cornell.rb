class IngestCornell < IngestBase

  # Description example: https://digital.library.cornell.edu/catalog/ss:24416106
  def doIngest(inst_id, coll_id)
    inst = Inst.find_by(pid: inst_id)
    coll = Coll.find_by(pid: coll_id)

    page = 1
    while page < 10
      base_url = "https://digital.library.cornell.edu/?f%5Bcollection_tesim%5D%5B%5D=Postcards+of+female+and+male+impersonators+and+cross-dressing+in+Europe+and+the+United+States%2C+1900-1930&page=#{page}&per_page=100&search_field=all_fields&view=gallery&format=json"
      page += 1
      #current_url = base_url
      web_content = IngestBase.fetch(base_url)

      web_content_json = JSON.parse(web_content)

      records = web_content_json["response"]["docs"]

      records.each do |record|
        id = record["id"]
        show_url = "https://digital.library.cornell.edu/catalog/#{id}"

        puts "Show URL: " + show_url

        if GenericObject.find_by(identifier: show_url).present?
          puts 'Already ingested'
          next
        end

        if record["title_ssi"].include?("(verso)") || record["id_number_tesim"][0].end_with?("_02") || record["id_number_tesim"][0].end_with?("_03")
          next
        end

        record_content = IngestBase.fetch("#{show_url}.json")
        record_content_json = JSON.parse(record_content)["response"]["document"]

        #image_link = record["download_link_tesim"][0]
        #image_link = record["media_URL_size_3_tesim"][0] # on side was 512
        image_url = record["media_URL_tesim"][0]
        filename = record["filename_s"][0]
        image_extension = record["img_file_extension_tesim"][0]

        # FIXME: Rights!!!
        @generic_object = GenericObject.new
        @generic_object.hosted_elsewhere = 1
        @generic_object.identifier = show_url
        @generic_object.is_shown_at = show_url
        @generic_object.title = record["title_ssi"]
        @generic_object.flagged = "No explicit content"
        @generic_object.visibility = "private"
        @generic_object.inst = inst
        @generic_object.coll = coll
        #@generic_object.rights = "Copyright not evaluated"
        @generic_object.rights = "No known copyright"

        format = record["format_tesim"][0]
        case format.downcase
        when "image"
          format_standard = "Still Image"
        else
          format_standard = "Still Image"
        end
        @generic_object.resource_types = [format_standard]

        if record_content_json["description_tesim"].present?
          record_content_json["description_tesim"].each do |description|
            @generic_object.descriptions += [description]
          end
        end

        # countries and locations
        if record_content_json["r1_location_tesim"].present?
          record_content_json["r1_location_tesim"].each do |location|
            case location.strip
            when "Paris"
              @generic_object.geonames += ["http://www.geonames.org/2988507"]
            when "Paris, France"
              @generic_object.geonames += ["http://www.geonames.org/2988507"]
            when "London"
              @generic_object.geonames += ["http://www.geonames.org/2643743"]
            when "Nancy"
              @generic_object.geonames += ["http://www.geonames.org/2990999"]
            when "Langensalza, Germany"
              @generic_object.geonames += ["http://www.geonames.org/2953413"]
            when "Vienna, Austria"
              @generic_object.geonames += ["http://www.geonames.org/2761369"]
            when "Cottbus"
              @generic_object.geonames += ["http://www.geonames.org/2939811"]
            when "Dijon"
              @generic_object.geonames += ["http://www.geonames.org/3021372"]
            when "Argentan"
              @generic_object.geonames += ["http://www.geonames.org/3037051"]
            when "Angers"
              @generic_object.geonames += ["http://www.geonames.org/3037656"]
            when "Barcelona"
              @generic_object.geonames += ["http://www.geonames.org/3128760"]
            when "Berlin"
              @generic_object.geonames += ["http://www.geonames.org/2950159"]
            when "Lyon"
              @generic_object.geonames += ["http://www.geonames.org/2996944"]
            when "Marseille"
              @generic_object.geonames += ["http://www.geonames.org/2995469"]
            when "Melun"
              @generic_object.geonames += ["http://www.geonames.org/2994651"]
            when "Stockholm"
              @generic_object.geonames += ["http://www.geonames.org/2673730"]
            when "Milan"
              @generic_object.geonames += ["http://www.geonames.org/3173435"]
            when "New York"
              @generic_object.geonames += ["http://www.geonames.org/5128581"]

            when "Birmingham"
              @generic_object.geonames += ["http://www.geonames.org/2655603"]
            when "Blackpool"
              @generic_object.geonames += ["http://www.geonames.org/2655459"]
            when "Bognor"
              @generic_object.geonames += ["http://www.geonames.org/2655262"]
            when "Brighton, UK"
              @generic_object.geonames += ["http://www.geonames.org/2654710"]
            when "Brooklyn, New York"
              @generic_object.geonames += ["http://www.geonames.org/5110302"]
            when "Bucharest"
              @generic_object.geonames += ["http://www.geonames.org/683506"]
            when "Chatillon"
              @generic_object.geonames += ["http://www.geonames.org/3026083"]
            when "Cherbourg"
              @generic_object.geonames += ["http://www.geonames.org/3025466"]

            when "Defiance, Iowa"
              @generic_object.geonames += ["http://www.geonames.org/4831806"]
            when "Dresden"
              @generic_object.geonames += ["http://www.geonames.org/2935022"]
            when "Gustrow"
              @generic_object.geonames += ["http://www.geonames.org/2913433"]
            when "Holmfirth"
              @generic_object.geonames += ["http://www.geonames.org/2646716"]
            when "Ingolstadt"
              @generic_object.geonames += ["http://www.geonames.org/2895992"]
            when "Konigsbruck"
              @generic_object.geonames += ["http://www.geonames.org/2885910"]
            when "Littlehampton"
              @generic_object.geonames += ["http://www.geonames.org/2644319"]
            when "Longton, UK"
              @generic_object.geonames += ["http://www.geonames.org/2643620"]

            when "Madrid, Spain"
              @generic_object.geonames += ["http://www.geonames.org/3117735"]
            when "Nantes"
              @generic_object.geonames += ["http://www.geonames.org/2990969"]
            when "Niort"
              @generic_object.geonames += ["http://www.geonames.org/2990355"]
            when "Paderborn"
              @generic_object.geonames += ["http://www.geonames.org/2855745"]
            when "Poitiers"
              @generic_object.geonames += ["http://www.geonames.org/2986495"]
            when "Pontivy"
              @generic_object.geonames += ["http://www.geonames.org/2986160"]
            when "Saint-Brieuc"
              @generic_object.geonames += ["http://www.geonames.org/2981280"]
            when "San Francisco, California"
              @generic_object.geonames += ["http://www.geonames.org/5391959"]
            when "Schonach"
              @generic_object.geonames += ["http://www.geonames.org/2837096"]
            when "Terni (Italy)"
              @generic_object.geonames += ["http://www.geonames.org/3165771"]
            when "Berlin, Schleswig-Holstein, Germany"
              @generic_object.geonames += ["http://www.geonames.org/2950158"]
            when "Milan, Italy"
              @generic_object.geonames += ["http://www.geonames.org/3173435"]
            else
              raise "Count not get location for: #{location}"
            end
          end
        end

        if record_content_json["r1_location_tesim"].blank? and record["country_tesim"].present?
          record["country_tesim"].each do |country|
            case country
            when "Germany"
              @generic_object.geonames += ["http://www.geonames.org/2921044"]
            when "France"
              @generic_object.geonames += ["http://www.geonames.org/3017382"]
            when "United Kingdom"
              @generic_object.geonames += ["http://www.geonames.org/2635167"]
            when "Sweden"
              @generic_object.geonames += ["http://www.geonames.org/2661886"]
            when "Belgium"
              @generic_object.geonames += ["http://www.geonames.org/2802361"]
            when "Italy"
              @generic_object.geonames += ["http://www.geonames.org/3175395"]
            else
              raise "Count not get country for: #{country}"
            end
          end
        end
        # languages like "German"
        if record_content_json["r1_language_tesim"].present?
          record_content_json["r1_language_tesim"].each do |language|
            if ISO_639.find_by_english_name(language).present?
              authority_check = Qa::Authorities::Loc.subauthority_for('iso639-2')
              authority_result = authority_check.search(language)
              authority_result.map! { |item| { text: item["label"], id: item["id"].gsub('info:lc', 'http://id.loc.gov') } }
              @generic_object.languages += [authority_result[0][:id]]
            end
          end
        end

        # additional rights information
        if record_content_json["rights_tesim"].present?
          record_content_json["rights_tesim"].each do |rights|
            @generic_object.rights_free_text += [rights]
          end
        end

        # subjects
        # Samples: Female impersonators,
        if record_content_json["subject_tesim"].present?
          record_content_json["subject_tesim"].each do |subject|
            attempt_homosaurus = HomosaurusV3Subject.find_by(label: subject)
            if attempt_homosaurus.present?
              @generic_object.homosaurus_uri_subjects += [attempt_homosaurus.uri]
            end
          end
        end

        @generic_object.genres = ["Ephemera"]

        # analogue format
        # "[[{"measurement":"14 x 9.1","measurement_units":"centimeters"}]]"
        if record_content_json["measurement_hash_tesim"].present?
          record_content_json["measurement_hash_tesim"].each do |measurement_hash|
            measurement_hash.gsub!("[[", "")
            measurement_hash.gsub!("]]", "")
            measurement_hash_json = JSON(measurement_hash)
            measurement_text = "#{measurement_hash_json['measurement']} (#{measurement_hash_json['measurement_units']})"
            @generic_object.analog_format = measurement_text
          end
        end

        # dates like "ca. 1900"
        if record_content_json["date_tesim"].present?
          record_content_json["date_tesim"].each do |date|
            insert_date_created(date)
          end
        end

        creators = []
        if record_content_json["agent_hash_tesim"].present?
          agent_hash = record_content_json["agent_hash_tesim"][0]
          agent_hash_list_json = JSON(agent_hash)
          agent_hash_list_json.each do |agent_hash_json_item|
            agent_hash_json = agent_hash_json_item[0]
            case agent_hash_json["agent_role"]
            when "publisher"
              creators += standardize_creator_name(agent_hash_json["agent"])
            when "photographer"
              creators += standardize_creator_name(agent_hash_json["agent"])
            when "performer"
              @generic_object.other_subjects += standardize_other_subject_name(agent_hash_json["agent"])
            else
              raise "Unprocessed agent role of: #{agent_hash_json['agent_role']} for record: #{show_url}"
            end
          end
        end

        if record_content_json["creator_ssi"].present?
          creators += standardize_creator_name(record_content_json["creator_ssi"])
        end

      @generic_object.creators = creators.uniq

      # image stuff
        puts image_url
        puts show_url
        image = MiniMagick::Image.open(image_url)
        image.format "jpg"
        image.resize "500x600"
        @generic_object.add_file(image.to_blob, 'image/jpeg', filename)

        @generic_object.save!

        @generic_object.base_files.each do |file|
          file.create_derivatives
        end

        # Fixme... would be best if this was after derivatives
        @generic_object.reload
        @generic_object.send_solr
      end
    end
  end

  def standardize_creator_name(name)
    if name == "Tilley, Vesta or Powles, Matilda Alice (1864-1952)"
      #return ["Vesta Tilley", "Matilda Alice Powles"]
      return ["Tilley, Vesta", "Powles, Matilda Alice"]
    elsif name == "Randall, Harry or Randall, Thomas William (1857-1932)"
      return ["Randall, Harry", "Randall, Thomas William"]
    elsif name == "Ray, Gabrielle or Cook, Gabriell Elizabeth Clifford (1883-1973)"
      return ["Ray, Gabrielle", "Cook, Gabriell Elizabeth Clifford"]
    elsif name == "Robey, George or Wade, Sir George Edward (1869-1954)"
      return ["Robey, George", "Wade, Sir George Edward"]
    elsif name == "F. K. ed (Freres Kunzli)" || name == "F.K. (Freres Kunzli)" || name.include?("F.K.")
      return  ["Kunzli, Freres"]
    elsif name == "Imprimeries Reunies."
      return ["Imprimeries Reunies"]
    elsif name == "John Grafton"
      return ["Graffton, John"]
    elsif name == "Oscar Hertzberg"
      return ["Hertzberg, Oscar"]
    elsif name == "Maurice Boisdon"
      return ["Boisdon, Maurice"]
    elsif name == "Monte Verdi"
      return ["Verdi, Monte"]
    elsif name == "Mlle Noray"
      return ["Noray, Mlle"]
    elsif name == "Sarah Bernhardt"
      return ["Bernhardt, Sarah"]
    elsif name == "Yvette Dolly"
      return ["Dolly, Yvette"]
    elsif name == "Thon Lind"
      return ["Lind, Thon"]
    elsif name == "Robert Bertin"
      return ["Bertin, Robert"]
    elsif name == "Clara Faurens"
      return ["Faurens, Clara"]
    elsif name == "Pol Simon"
      return ["Simon, Pol"]
    elsif name == "Monsieur D'Hernonville"
      return ["D'Hernonville"]
    elsif name.start_with?("Edit. d")
      return ["Edit. d'Art"]
    elsif name == "Jules Robuchon"
      return ["Robuchon, Jules"]
    elsif name == "Suzanne and Blanche Mante"
      return ["Mante, Suzanne", "Mante, Blanche"]
    elsif name == "Fanny and Alice de Tender"
      return ["Tender, Fanny", "Tender, Alice"]
    elsif name == "Louis Vernassier"
      return ["Vernassier, Louis"]
    else
      name = name.split(" (")[0]
      name = name.gsub(/\, \d\d\d\d\-\d\d\d\d$/, "")
      name.strip!
      return [name]
    end
  end

  def standardize_other_subject_name(name)
    if name == "Tilley, Vesta or Powles, Matilda Alice (1864-1952)"
      return ["Vesta Tilley", "Matilda Alice Powles"]
    elsif name == "Randall, Harry or Randall, Thomas William (1857-1932)"
      return ["Harry Randall", "Thomas William Randall"]
    elsif name == "Ray, Gabrielle or Cook, Gabriell Elizabeth Clifford (1883-1973)"
      return ["Gabrielle Ray", "Gabriell Elizabeth Clifford Cook"]
    elsif name == "Robey, George or Wade, Sir George Edward (1869-1954)"
      return ["George Robey", "Sir George Edward Wade"]
    elsif name == "F. K. ed (Freres Kunzli)" || name == "F.K. (Freres Kunzli)" || name.include?("F.K.")
      return  ["Freres Kunzli"]
    elsif name == "Imprimeries Reunies."
      return ["Imprimeries Reunies"]
    elsif name.start_with?("Edit. d")
      return ["Edit. d'Art"]
    elsif name == "Fanny and Alice de Tender"
      return ["Fanny de Tender", "Alice de Tender"]
    elsif name == "Monsieur D'Hernonville"
      return ["D'Hernonville"]
    elsif name == "Suzanne and Blanche Mante"
      return ["Suzanne Mante", "Blanche Mante"]
    else
      name = name.split(" (")[0]
      name = name.gsub(/\, \d\d\d\d\-\d\d\d\d$/, "")
      if name.include?(", ")
        name = name.split(", ")[1] + " " + name.split(", ")[0]
      elsif name.include?(",")
        name = name.split(",")[1] + " " + name.split(",")[0]
      end
      name.strip!
      return [name]
    end
  end

  def clear_records(coll_id)
    coll = Coll.find_by(pid: coll_id)
    object_to_destroy = []
    coll.generic_objects.each do |obj|
      object_to_destroy << obj
    end

    object_to_destroy.each do |obj|
      obj.destroy!
    end
    #GenericObject.where
  end
end