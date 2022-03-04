module GenericObjectAssignments

  def clean_values(value)
    case value.class.to_s
      when 'String'
        return [value]
      when 'Array'
        return value.uniq
      when 'Integer'
        return [value.to_s]
      when '' # nil case
        return []
      else
        return [value]
    end
  end

  # Custom
  def set_original_info(obj, mime_type, original_name, original_size)
    if original_name.present?
      if File.extname(original_name).size < 6
        obj.original_filename = original_name.gsub(File.extname(original_name), '')
        obj.original_extension = File.extname(original_name)
      else
        obj.original_filename = original_name
        obj.original_extension = ".#{BaseFile.calculate_extension(mime_type)}"
      end
    end
    obj.size = original_size if original_size.present?
  end

  def add_file(content, mime_type, original_name)
    if mime_type.include? 'image'
      self.add_image(content, mime_type, original_name)
    elsif mime_type.include? 'pdf'
      self.add_pdf(content, mime_type, original_name)
    else
      raise 'Unsupported yet'
    end
  end

  def add_image(value, mime_type, original_name=nil, original_size=nil)
    sha256 = BaseFile.calculate_sha256 value
    obj = ImageFile.find_or_initialize_by(sha256: sha256, mime_type: mime_type, generic_object_id: self.id)
    self.base_files << obj unless self.base_files.include? obj
    self.set_original_info(obj, mime_type, original_name, original_size)
    obj.content = value
    obj.save!
  end

  def add_pdf(value, mime_type, original_name=nil, original_size=nil)
    sha256 = BaseFile.calculate_sha256 value
    obj = PdfFile.find_or_initialize_by(sha256: sha256, mime_type: mime_type, generic_object_id: self.id)
    self.base_files << obj unless self.base_files.include? obj
    self.set_original_info(obj, mime_type, original_name, original_size)
    obj.content = value
    obj.save!
  end

  def add_document(value, mime_type, original_name=nil, original_size=nil)
    sha256 = BaseFile.calculate_sha256 value
    obj = DocumentFile.find_or_initialize_by(sha256: sha256, mime_type: mime_type, generic_object_id: self.id)
    self.base_files << obj unless self.base_files.include? obj
    self.set_original_info(obj, mime_type, original_name, original_size)
    obj.content = value
    obj.save!
  end

  # Has Many Relationships
  def other_subjects=(value)
    r = []
    values = clean_values(value)
    values.each do |val|
      if val.class == String
        r << OtherSubject.find_or_initialize_by(label: val, generic_object_id: self.id)
      elsif val.class == OtherSubject
        r << val
      else
        raise 'Unhandled GenericObject assignment for: ' + val.class.to_s
      end
    end
    value = r
    super
  end

  def creators=(value)
    r = []
    values = clean_values(value)
    values.each do |val|
      if val.class == String
        r << Creator.find_or_initialize_by(label: val, generic_object_id: self.id)
      elsif val.class == Creator
        r << val
      else
        raise 'Unhandled GenericObject assignment for: ' + val.class.to_s
      end
    end
    value = r
    super
  end

  def contributors=(value)
    r = []
    values = clean_values(value)
    values.each do |val|
      if val.class == String
        r << Contributor.find_or_initialize_by(label: val, generic_object_id: self.id)
      elsif val.class == Contributor
        r << val
      else
        raise 'Unhandled GenericObject assignment for: ' + val.class.to_s
      end
    end
    value = r
    super
  end

  # Many to Many relationships
  def genres=(value)
    r = []
    values = clean_values(value)
    values.each do |val|
      if val.class == String
        r << Genre.find_by(label: val)
        raise "Could not find genre for: #{val.to_s}" if r.last.nil?
      elsif val.class == Genre
        r << val
      else
        raise 'Unhandled GenericObject assignment for: ' + val.class.to_s
      end
    end
    value = r
    super
  end

  def resource_types=(value)
    r = []
    values = clean_values(value)
    values.each do |val|
      if val.class == String
        r << ResourceType.find_by(label: val)
        raise "Could not find resource type for: #{val.to_s}" if r.last.nil?
      elsif val.class == ResourceType
        r << val
      else
        raise 'Unhandled GenericObject assignment for: ' + val.class.to_s
      end
    end
    value = r
    super
  end

  def rights=(value)
    r = []
    values = clean_values(value)
    values.each do |val|
      if val.class == String
        r << Rights.find_by(label: val)
        raise "Could not find rights for: #{val.to_s}" if r.last.nil?
      elsif val.class == Rights
        r << val
      else
        raise 'Unhandled GenericObject assignment for: ' + val.class.to_s
      end
    end
    value = r
    super
  end

  def homosaurus_subjects=(value)
    r = []
    values = clean_values(value)
    values.each do |val|
      if val.class == String
        r << HomosaurusSubject.find_by(uri: val)
        raise "Could not find homosaurus for: #{val.to_s}" if r.last.nil?
      elsif val.class == HomosaurusSubject
        r << val
      else
        raise 'Unhandled GenericObject assignment for: ' + val.class.to_s
      end
    end
    value = r
    super
  end

  def homosaurus_v2_subjects=(value)
    r = []
    values = clean_values(value)
    values.each do |val|
      if val.class == String
        r << HomosaurusV2Subject.find_by(uri: val)
        raise "Could not find homosaurus V2 for: #{val.to_s}" if r.last.nil?
      elsif val.class == HomosaurusV2Subject
        r << val
      else
        raise 'Unhandled GenericObject assignment for: ' + val.class.to_s
      end
    end
    value = r
    super
  end

  def homosaurus_uri_subjects=(value)
    r = []
    values = clean_values(value)
    values.each do |val|
      if val.class == String
        term = HomosaurusUriAutocomplete.find_by_id(val)
        label = term["prefLabel_ssim"][0]
        language_label_list = []
        if term["languageLabel_ssim"].present?
          term["languageLabel_ssim"].each do |lang_label|
            language_label_list << lang_label.split('@')[0]
          end
        end

        alt_label_list = term["altLabel_ssim"] if term["altLabel_ssim"].present?
        alt_label_list ||= []
        #TODO: Broader? Narrower? Etc?

        ld = HomosaurusUriSubject.find_by(uri: val)
        if ld.blank?
          ld = HomosaurusUriSubject.create(uri: val, label: label, language_labels: language_label_list, alt_labels: alt_label_list)
        else
          was_changed = false
          if ld.label != label
            ld.label = label
            was_changed = true
          end

          if ld.alt_labels.sort != alt_label_list.sort
            ld.alt_labels = alt_label_list
            was_changed = true
          end

          ld.save! if was_changed
        end
        r << ld
        raise "Could not find lcsh for: #{val.to_s}" if r.last.nil?
      elsif val.class == HomosaurusUriSubject
        r << val
      else
        raise 'Unhandled GenericObject assignment for: ' + val.class.to_s
      end
    end
    value = r
    super
  end

  # Linked Data Special Case
  def lcsh_subjects=(value)
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

  def geonames=(value)
    r = []
    values = clean_values(value)
    values.each do |val|
      if val.class == String
        ld = Geoname.find_by(uri: val)
        if ld.blank?
          geojson_hash_base = {type: 'Feature', geometry: {type: 'Point'}}
          payload = {:geonameId=>"#{val.split('/').last}", :username=>"boston_library"}
          url = 'http://api.geonames.org/getJSON'
          if Settings.dta_config["proxy_host"].present?
            req = RestClient::Request.execute(method: :get, url: url, :headers => {params: payload, accept: :json}, proxy: "http://#{Settings.dta_config['proxy_host']}:#{Settings.dta_config['proxy_port']}")
          else
            req = RestClient.get url, {:params => payload, accept: :json}
          end

          result = JSON.parse(req)
          # FIXME: This indicates a bad geographic element... need to verify on input
          if result['name'].blank? || result['lng'].blank?
            raise "Error: Geonames value of #{val} is invalid for #{self.id}"
          end

          geojson_hash_base[:geometry][:coordinates] = [result['lng'],result['lat']]

          if result['fcl'] == 'P' and result['adminCode1'].present?
            #geojson_hash_base[:properties] = {placename: result['name'] + ', ' + result['adminCode1']}
            geojson_hash_base[:properties] = {placename: result['name']}
          else
            geojson_hash_base[:properties] = {placename: result['name']}
          end

          hierarchy_full = []
          hierarchy_full << result['name']
          hierarchy_full << result['adminName1'] if result['adminName1'].present?
          hierarchy_full << result['adminName2'] if result['adminName2'].present?
          hierarchy_full << result['adminName3'] if result['adminName3'].present?
          hierarchy_full << result['countryName'] if result['countryName'].present?
          hierarchy_full.uniq!

          hierarchy_display = []
          hierarchy_display << result['adminName1'] if result['adminName1'].present?
          hierarchy_display << result['adminName2'] if result['adminName2'].present?
          hierarchy_display << result['adminName3'] if result['adminName3'].present?
          hierarchy_display << result['name']
          hierarchy_display.uniq!

          # TODO: Get all Labels?
          ld = Geoname.create(uri: val, label: result['name'], lat: result['lat'], lng: result['lng'], hierarchy_full: hierarchy_full, hierarchy_display: hierarchy_display, geo_json_hash: geojson_hash_base)
        end
        r << ld
        raise "Could not find geonames for: #{val.to_s}" if r.last.nil?
      elsif val.class == Geoname
        r << val
      else
        raise 'Unhandled GenericObject assignment for: ' + val.class.to_s
      end
    end
    value = r
    super
  end

end
