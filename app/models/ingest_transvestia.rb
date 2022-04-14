class IngestTransvestia < IngestBase

  # Manifest doesn't work as it doesn't include multiple fields... wow
  # keyword, contributor, etc
  # See: https://vault.library.uvic.ca/concern/generic_works/a731bcd8-619f-41fb-9001-67bbcfda5e6d vs https://vault.library.uvic.ca/concern/generic_works/a731bcd8-619f-41fb-9001-67bbcfda5e6d/manifest.json
  def doIngest(inst_id, coll_id)
    inst = Inst.find_by(pid: inst_id)
    coll = Coll.find_by(pid: coll_id)

    page = 1
    while page < 3
      base_url = "https://vault.library.uvic.ca/collections/6576cedf-1282-4089-8351-08f73f4199b4?locale=en&page=#{page}&per_page=100"
      page += 1
      #current_url = base_url
      web_content = IngestBase.fetch_links(base_url)

      final_links = []
      web_content.each do |content|
        content_split = content.split('?')[0]
        if !content_split.include?('/edit') && content_split.include?('/concern/generic_works/')
          final_links << content_split
        end
      end
      final_links.uniq!

      final_links.each do |record|
        show_url = "https://vault.library.uvic.ca#{record}"

        puts "Show URL: " + show_url

        if GenericObject.find_by(is_shown_at: show_url).present?
          puts 'Already ingested'
          next
        end

        record_content_manifest = IngestBase.fetch("#{show_url}/manifest.json")
        record_content_manifest_json = JSON.parse(record_content_manifest)

        record_content = IngestBase.fetch("#{show_url}.json")
        record_content_json = JSON.parse(record_content)

        @generic_object = GenericObject.new
        @generic_object.hosted_elsewhere = 1
        @generic_object.identifier = show_url
        @generic_object.is_shown_at = show_url
        @generic_object.title = record_content_manifest_json["label"]
        @generic_object.flagged = "No explicit content"
        @generic_object.visibility = "private"
        @generic_object.inst = inst
        @generic_object.coll = coll
        #@generic_object.rights = "Copyright not evaluated"


        if record_content_manifest_json["description"].present?
          record_content_manifest_json["description"].each do |description|
            @generic_object.descriptions += [description]
          end
        end

        homosaurus_subjects = []

        if record_content_json["geographic_coverage"].present? and record_content_json["geographic_coverage"][0].present?
          raise "Missing Georgrapic content"
        end

        if record_content_json["extent"].present? and record_content_json["extent"][0].present?
          @generic_object.analog_format = record_content_json["extent"][0]
        end

        if record_content_json["keyword"].present? and record_content_json["keyword"][0].present?
          record_content_json["keyword"].each do |keyword|
            case keyword
            when "transgender (general)"
              #ignore
            when "crossdressing"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0000318"
            when "transfeminine"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0001382"
            when "hormone therapy"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0000317"
            when "activist"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0000007"
            else
              raise "Need subject for #{keyword}"
            end
          end
        end

        if record_content_json["publisher"].present? and record_content_json["publisher"][0].present?
          record_content_json["publisher"].each do |publisher|
            @generic_object.publishers += [publisher]
          end
        end

        if record_content_json["date_created"].present? and record_content_json["date_created"][0].present?
          insert_date_created(record_content_json["date_created"][0])
        end

        if record_content_json["alternative_title"].present? and record_content_json["alternative_title"][0].present?
          record_content_json["alternative_title"].each do |alt_title|
            @generic_object.alt_titles += [alt_title]
          end
        end

        if record_content_json["language"].present? and record_content_json["language"][0].present?
          record_content_json["language"].each do |language|
            if language == "eng"
              language = "en"
            end
            if ISO_639.find_by_code(language).present?
              language = ISO_639.find_by_code(language)[3]
              authority_check = Qa::Authorities::Loc.subauthority_for('iso639-2')
              authority_result = authority_check.search(language)
              authority_result.map! { |item| { text: item["label"], id: item["id"].gsub('info:lc', 'http://id.loc.gov') } }
              @generic_object.languages += [authority_result[0][:id]]
            end
          end
        end

        if record_content_json["contributor"].present? and record_content_json["contributor"][0].present?
          record_content_json["contributor"].each do |contributor_uri|
            if contributor_uri.include? 'http://'
              # http://id.worldcat.org/fast/506440
              # Want: http://id.worldcat.org/fast/506440.rdf.xml
              doc = IngestBase.fetch_xml("#{contributor_uri}.rdf.xml")
              nodeset = doc.xpath('//skos:prefLabel', 'skos' => 'http://www.w3.org/2004/02/skos/core#')
              contributor = nodeset[0].children.text
              @generic_object.contributors += [contributor]
            elsif contributor_uri.include?(', ')
              @generic_object.contributors += [contributor_uri]
            else
              raise "Unknown contributor value: #{contributor_uri}"
            end
          end
          @generic_object.contributors = @generic_object.contributors.uniq
        end



        # TO CHECK: Genre, Format, Keyword (subjects), Date Created, Provenance, Technical note
        # Keywords: https://vault.library.uvic.ca/concern/generic_works/fe1b83c3-eedd-4f4f-8c9c-cd5600642859?locale=en
        # Also whether to include "Pocket Sized" records.
        record_content_manifest_json["metadata"].each do |field|
          case field["label"]
          when "Contributor label"
            # @generic_object.contributors += [field["value"]]
          when "Contributor"
            # do nothing
          when "Identifier"
            @generic_object.identifier = field["value"]
          when "Date created"
            # Sample: January 1960
            # insert_date_created(field["value"])
          when "Rights statement"
            if field["value"] == "http://rightsstatements.org/vocab/InC-EDU/1.0/"
              @generic_object.rights = "In copyright"
              # technically should be: http://rightsstatements.org/page/InC-EDU/1.0/?language=en
            elsif field["value"] == "https://creativecommons.org/publicdomain/mark/1.0/"
              @generic_object.rights = "No known copyright"
            else
              raise "Need copyright for: #{field['value']}"
            end
          when "License"
            @generic_object.rights_free_text += [field["value"]]
          when "Physical repository label"
            # sample: University of Victoria (B.C.). Library
          when "Physical repository"
            # sample: http://id.worldcat.org/fast/522461
          when "Collection"
            # sample: Transvestia
          when "Provenance"
            #sample: Transvestia was a part of the library holdings of the Rikki Swin Institute: Gender Education, Research, Library and Archives (RSI), located in Chicago, Illinois. Dedicated to transgender research and education, it opened to the public on March 22, 2001, to coincide with the 15th Annual Conference of the International Foundation for Gender Education. The Institute closed in December 2004. The Institute had four objectives: the housing of a library and archives; conference co-sponsorship; digital video education; and research. The RSI collection was donated by Rikki Swin to the University of Victoria Libraries in 2008, and is a foundational resource of UVic’s Transgender Archives.
          when "Provider label"
            # sample: University of Victoria (B.C.). Library
          when "Provider"
            # sample: http://id.worldcat.org/fast/522461
          when "Sponsor"
            # sample University of Victoria Transgender Archives
          when "Genre label"
            if field["value"] == "magazines (periodicals)"
              #@generic_object.genres = [something_hjere]
            else
              raise "Need genre for: #{field['label']}"
            end
          when "Genre"
            # sample: http://vocab.getty.edu/aat/300215389
          when "Date digitized"
            # sample: 2017-01
          when "Technical note"
            # sample: Scanned on the Opticbook A300, 600 dpi tiff.
          when "Year"
            # sample: 1960
          when "Additional physical characteristics"
            # illustrations
          when "Transcript"
            # 1
          else
            # ignore
          end
        end

        @generic_object.homosaurus_uri_subjects = homosaurus_subjects if homosaurus_subjects.present?
        @generic_object.genres = ["Periodicals"]
        @generic_object.resource_types = ["Text"]

        if @generic_object.date_created.blank?
          raise "Missing date for #{show_url}"
        end

        format_standard = "Still Image"
        @generic_object.resource_types = [format_standard]

      # image stuff
        image_content_links = IngestBase.fetch_images(show_url)
        image_main_link = image_content_links.select { |link| link.include?("/pdf_thumbnails/transvestia/") }[0]
        image_url = "https://vault.library.uvic.ca#{image_main_link}"
        IngestBase.process_image(@generic_object, image_url, image_url.split('/').last)

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