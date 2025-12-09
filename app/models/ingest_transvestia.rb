class IngestTransvestia < IngestBase

  # Manifest doesn't work as it doesn't include multiple fields... wow
  # keyword, contributor, etc
  # See: https://vault.library.uvic.ca/concern/generic_works/a731bcd8-619f-41fb-9001-67bbcfda5e6d vs https://vault.library.uvic.ca/concern/generic_works/a731bcd8-619f-41fb-9001-67bbcfda5e6d/manifest.json
  def doIngest(inst_id, coll_id, uvic_collection_id)
    inst = Inst.find_by(pid: inst_id)
    coll = Coll.find_by(pid: coll_id)

    page = 1
    while page < 3
      # base_url = "https://vault.library.uvic.ca/collections/6576cedf-1282-4089-8351-08f73f4199b4?locale=en&page=#{page}&per_page=100"
      # https://vault.library.uvic.ca/collections/12f35fc9-41e8-48b9-ba6a-a72ce98fac6f?locale=en&page=1&per_page=50
      base_url = "https://vault.library.uvic.ca/collections/#{uvic_collection_id}?locale=en&page=#{page}&per_page=50"
      puts "url is: #{base_url}"

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

        puts "Getting #{show_url}/manifest.json"
        # This is junk in recent records: https://vault.library.uvic.ca/concern/generic_works/7f7e4f8d-ae09-449b-b913-57eb67467cdf/manifest.json
        record_content_manifest = IngestBase.fetch("#{show_url}/manifest.json")
        record_content_manifest_json = JSON.parse(record_content_manifest)

        sleep(1)
        puts "Getting #{show_url}.json"
        # next if show_url.include? "678aa6da-57ef-4a79-a020-0676c7eb98f7"
        begin
          record_content = IngestBase.fetch("#{show_url}.json")
          record_content_json = JSON.parse(record_content)
        rescue
          next
        end

        @generic_object = GenericObject.new
        @generic_object.hosted_elsewhere = 1
        @generic_object.identifier = show_url
        @generic_object.is_shown_at = show_url
        @generic_object.title = record_content_json["title"][0]
        @generic_object.flagged = "No explicit content"
        @generic_object.visibility = "private"
        @generic_object.inst = inst
        @generic_object.coll = coll
        #@generic_object.rights = "Copyright not evaluated"


        if record_content_json["description"].present?
          record_content_json["description"].each do |description|
            @generic_object.descriptions += [description]
          end
        end

        homosaurus_subjects = []

        if record_content_json["geographic_coverage"].present? and record_content_json["geographic_coverage"][0].present?
          record_content_json["geographic_coverage"].each do |location|
            case location["id"].strip
            when "http://id.worldcat.org/fast/1204481"
              @generic_object.geonames += ["http://www.geonames.org/5391959"]
            when "http://id.worldcat.org/fast/1205020"
              @generic_object.geonames += ["http://www.geonames.org/5327684"]
            when "http://id.worldcat.org/fast/1204333"
              @generic_object.geonames += ["http://www.geonames.org/5128581"]
            when "http://id.worldcat.org/fast/1204048"
              @generic_object.geonames += ["http://www.geonames.org/4887398"]
            else
              raise "Missing Georgrapic content with id #{location["id"].strip}"
            end
          end
        end

        if record_content_json["extent"].present? and record_content_json["extent"][0].present?
          @generic_object.analog_format = record_content_json["extent"][0]
        end

        missing_subjects = []
        if record_content_json["keyword"].present? and record_content_json["keyword"][0].present?
          record_content_json["keyword"].each do |keyword|
            case keyword.downcase
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
            when "lesbian poets"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0003664"
            when "transgender authors"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0001727"
            when "lesbian authors"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0001724"
            when "lgbtq+ poetry"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0001118"
            when "trans men"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0001643"
            when "latino/a/x transgender people"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0001417"
            when "lgbtq+ spiritual people"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0000948"
            when "multiracial transgender people"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0001804"
            when "black transgender people"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0001396"
            when "lesbian poetry"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0000762"
            when "lgbtq+ poets"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0003663"
            when "transgender erotic literature"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0001600"
            when "transgender autobiographies"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0001733"
            when "black lgbtq+ people"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0000208"
            when "lgbtq+ people with substance use disorders"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0002226"
            when "lesbian fiction"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0000742"
            when "african american gay men"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0000463"
            when "lesbians"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0000556"
            when "prostitutes"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0003758"
            when "male prostitutes"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0003758" #Note: duplicates handled in the assignment
            when "gay men"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0000506"
            when "lgbtq+ people who use substances"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0000379"
            when "gay fiction"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0000493"
            when "butch-femme relationships"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0000230"
            when "lesbian erotic literature"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0001597"
            when "butch-femme"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0000230"
            when "transgender christians"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0001401"
            when "lgbtq+ christians"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0000265"
            when "lgbtq+ religious people"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0000928"
            when "lesbian christians"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0000731"
            when "bisexual fiction"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0000151"
            when "bisexual people"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0000170"
            when "sexuality"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0001306"
            when "multiracial lgbtq+ people"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0000903"
            when "lgbtq+ people with addictions"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0001550"
            when "bisexual erotic literature"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0001599"
            when "leather community"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0000705"
            when "lesbian bars"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0000724"
            when "lgbtq+ motorcycle clubs"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0000906"
            when "butches"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0000231"
            when "sex work"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0001276"
            when "black lesbians"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0000726"
            when "lesbian identity"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0000744"
            when "lesbian culture"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0000382"
            when "lesbian literary criticism"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0001603"
            when "transgender people"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0001378"
            when "trans women"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0001642"
            when "transgender fiction"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0001414"
            when "lgbtq+ fiction"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0000443"
            when "lgbtq+ people who use substances recreationally"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0001235"
            when "gender affirming surgery"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0000561"
            when "lgbtq+ people"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0000915"
            when "lgbtq+ culture"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0001831"
            when "testosterone"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0001362"
            when "transitioning (gender)"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0001465"
            when "substance use in lgbtq+ communities"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0000380"
            when "lesbian literature"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0000750"
            when "drag queens"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0000375"
            when "femmes"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0000440"
            when "lgbtq+ mistresses (bdsm culture)"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0001018"
            when "lesbian drama"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0000739"
            when "mtfs"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0000986"
            when "lgbtq+ older people"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0000393"
            when "lgbtq+ discrimination"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0000356"
            when "lgbtq+ authors"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0001723"
            when "mental health care for lgbtq+ people"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0001012"
            when "mental disorders"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0001011"
            when "lgbtq+ plays"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0000922"
            when "transgender drama"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0001411"
            when "transfeminine people"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0001382"
            when "transgender theater"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0001454"
            when "sexism"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0001278"
            when "racism"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0002038"
            when "bisexual drama"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0000149"
            when "african american bisexual people"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0000123"
            when "police harassment of lgbtq+ people"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0002375"
            when "gender non-conforming identity"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0001922"
            when "transgender community"
              homosaurus_subjects << "https://homosaurus.org/v3/homoit0001403"
            else
              missing_subjects << keyword.downcase
            end
          end
        end

        if missing_subjects[0].present?
          raise "Need subjects for #{missing_subjects}"
        end

        if record_content_json["genre"].present?
          if record_content_json["genre"].class == Array
            record_content_json["genre"].each do |genre|
              handle_genre(genre["id"])
            end
          else
            handle_genre(record_content_json["genre"]["id"])
          end
        else
          raise "Missing genre in top level for #{show_url}"
        end
        @generic_object.genres = @generic_object.genres.uniq


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
            if contributor_uri.class == Hash
              doc = IngestBase.fetch_xml("#{contributor_uri["id"]}.rdf.xml")
              nodeset = doc.xpath('//skos:prefLabel', 'skos' => 'http://www.w3.org/2004/02/skos/core#')
              contributor = nodeset[0].children.text
              @generic_object.contributors += [contributor]
            elsif contributor_uri.include? 'http://'
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

        raise "No rights_statement for ${show_url}" if record_content_json["rights_statement"].blank? || record_content_json["rights_statement"][0].blank?
        if record_content_json["rights_statement"][0] == "http://rightsstatements.org/vocab/InC-EDU/1.0/"
          @generic_object.rights = "In copyright"
          # technically should be: http://rightsstatements.org/page/InC-EDU/1.0/?language=en
        elsif record_content_json["rights_statement"][0] == "http://rightsstatements.org/vocab/InC/1.0/"
          @generic_object.rights = "In copyright"
        elsif record_content_json["rights_statement"][0] == "https://creativecommons.org/publicdomain/mark/1.0/"
          @generic_object.rights = "No known copyright"
        else
          raise "Need copyright for: #{record_content_json["rights_statement"][0]}"
        end

        if record_content_json["identifier"].present? and record_content_json["identifier"][0].present?
          record_content_json["identifier"].each do |identifier|
            @generic_object.identifier = identifier
          end
        end

        if record_content_json["license"].present? and record_content_json["license"][0].present?
          record_content_json["license"].each do |license|
            @generic_object.rights_free_text += [license]
          end
        end

        if record_content_json["creator"].present? and record_content_json["creator"][0].present?
          record_content_json["creator"].each do |contributor_uri|
            if contributor_uri.class == Hash
              doc = IngestBase.fetch_xml("#{contributor_uri["id"]}.rdf.xml")
              nodeset = doc.xpath('//skos:prefLabel', 'skos' => 'http://www.w3.org/2004/02/skos/core#')
              contributor = nodeset[0].children.text
              @generic_object.creators += [contributor]
            elsif contributor_uri.include? 'http://'
              # http://id.worldcat.org/fast/506440
              # Want: http://id.worldcat.org/fast/506440.rdf.xml
              doc = IngestBase.fetch_xml("#{contributor_uri}.rdf.xml")
              nodeset = doc.xpath('//skos:prefLabel', 'skos' => 'http://www.w3.org/2004/02/skos/core#')
              contributor = nodeset[0].children.text
              @generic_object.creators += [contributor]
            elsif contributor_uri.include?(', ')
              @generic_object.creators += [contributor_uri]
            else
              raise "Unknown creator value: #{contributor_uri}"
            end
          end
          @generic_object.creators = @generic_object.creators.uniq
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
            # @generic_object.identifier = field["value"]
          when "Date created"
            # Sample: January 1960
            # insert_date_created(field["value"])
          when "Rights statement"
=begin
            if field["value"] == "http://rightsstatements.org/vocab/InC-EDU/1.0/"
              @generic_object.rights = "In copyright"
              # technically should be: http://rightsstatements.org/page/InC-EDU/1.0/?language=en
            elsif field["value"] == "http://rightsstatements.org/vocab/InC/1.0/"
              @generic_object.rights = "In copyright"
            elsif field["value"] == ["<a href='http://rightsstatements.org/vocab/InC/1.0/' target='blank'>In Copyright</a>"]
              @generic_object.rights = "In copyright"
            elsif field["value"] == "https://creativecommons.org/publicdomain/mark/1.0/"
              @generic_object.rights = "No known copyright"
            else
              raise "Need copyright for: #{field['value']} of type #{field['value'].class.to_s}}"
            end
=end
          when "License"
                      # @generic_object.rights_free_text += [field["value"]]
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

        if @generic_object.resource_types.blank?
          raise "Missing resource type for #{show_url} "
        end
          #@generic_object.resource_types = ["Text"]
        #@generic_object.genres = ["Periodicals"]

        if @generic_object.date_created.blank?
          unless show_url == "https://vault.library.uvic.ca/concern/generic_works/678aa6da-57ef-4a79-a020-0676c7eb98f7"
            raise "Missing date for #{show_url}"
          end

        end

        # format_standard = "Still Image"
        # @generic_object.resource_types = [format_standard]

      # image stuff
        image_content_links = IngestBase.fetch_images(show_url)
        image_main_link = image_content_links.select { |link| link.include?("/pdf_thumbnails/transvestia/") }[0]
        if image_main_link.blank?
          image_main_link = image_content_links.select { |link| link.include?("?file=thumbnail") }[0]
        end

        if image_main_link.present?
          image_url = "https://vault.library.uvic.ca#{image_main_link}"
          puts "Processing image: #{image_url}"
          IngestBase.process_image(@generic_object, image_url, image_url.split('/').last)
        end

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

  def handle_genre val
    # sample: http://vocab.getty.edu/aat/300215389
    if val.downcase == "http://vocab.getty.edu/aat/300028633"
      @generic_object.resource_types = ["Audio"]
      @generic_object.genres += @generic_object.genres + ["Sound Recordings"]
    elsif val.downcase == "http://vocab.getty.edu/aat/300055931" || val.downcase == "http://vocab.getty.edu/aat/300026451"
      @generic_object.genres += @generic_object.genres + ["Poetry"]
      handle_genre_resource_type_still_image(val)
    elsif val.downcase == "http://vocab.getty.edu/aat/300028051" || val.downcase == "http://vocab.getty.edu/aat/300202580" || val.downcase == "http://vocab.getty.edu/aat/300055918" || val.downcase == "http://vocab.getty.edu/aat/300311670"
      @generic_object.genres += @generic_object.genres + ["Books"]
      handle_genre_resource_type_still_image(val)
    elsif val.downcase == "http://vocab.getty.edu/aat/300026059" || val.downcase == "http://vocab.getty.edu/aat/300417739"
      @generic_object.genres += @generic_object.genres + ["Catalogs"]
      handle_genre_resource_type_still_image(val)
    elsif val.downcase == "http://vocab.getty.edu/aat/300375156" || val.downcase == "http://vocab.getty.edu/aat/300028682" || val.downcase == "https://vocab.getty.edu/aat/300263836" || val.downcase == "http://vocab.getty.edu/aat/300263836"
      @generic_object.genres += @generic_object.genres + ["Motion Pictures"]
      @generic_object.resource_types = ["Moving image"]
    elsif val.downcase == "http://vocab.getty.edu/aat/300026291"
      @generic_object.genres += @generic_object.genres + ["Essays"]
      handle_genre_resource_type_still_image(val)
    elsif val.downcase == "http://vocab.getty.edu/aat/300048715"
      @generic_object.genres += @generic_object.genres + ["Articles"]
      handle_genre_resource_type_still_image(val)
    elsif val.downcase == "http://vocab.getty.edu/aat/300026879"
      @generic_object.genres += @generic_object.genres + ["Correspondence"]
      handle_genre_resource_type_still_image(val)
    elsif val.downcase == "http://vocab.getty.edu/aat/300080104"
      @generic_object.genres += @generic_object.genres + ["Autobiographies"]
      handle_genre_resource_type_still_image(val)
    elsif val.downcase == "http://vocab.getty.edu/aat/300026480" # reviews (documents)
      @generic_object.genres += @generic_object.genres + ["Reviews"]
      handle_genre_resource_type_still_image(val)
    elsif val.downcase == "http://vocab.getty.edu/aat/300111999" || val.downcase == "http://vocab.getty.edu/aat/300026931" # publications (documents) and drafts (documents)
      @generic_object.genres += @generic_object.genres + ["Documents"]
      handle_genre_resource_type_still_image(val)
    elsif val.downcase == "http://vocab.getty.edu/aat/300417554" # drama (literary genre)
      @generic_object.genres += @generic_object.genres + ["Drama"]
      handle_genre_resource_type_still_image(val)
      # ignore cases
    elsif val.downcase == "http://vocab.getty.edu/aat/300343729" # letters to the editor
      handle_genre_resource_type_still_image(val)
    elsif val.downcase == "http://vocab.getty.edu/aat/300451696" # plays (literary genre)
      handle_genre_resource_type_still_image(val)
    elsif val.downcase == "http://vocab.getty.edu/aat/300026491" # screenplays
      handle_genre_resource_type_still_image(val)
    elsif val.downcase == "http://vocab.getty.edu/aat/300265770" # autofiction
      handle_genre_resource_type_still_image(val)
    elsif val.downcase == "http://vocab.getty.edu/aat/300136847" # photocopies
      handle_genre_resource_type_still_image(val)
    else
      raise "Need genre for: #{val}"
    end
  end

  def handle_genre_resource_type_still_image val
    unless @generic_object.resource_types.include?("Audio") || @generic_object.resource_types.include?("Moving image")
      @generic_object.resource_types = ["Still Image"]
    end
    @generic_object.resource_types = @generic_object.resource_types.uniq
  end
end