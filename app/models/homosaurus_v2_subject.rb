class HomosaurusV2Subject < HomosaurusSubject

  def self.loadV2(xml_location)
    ActiveRecord::Base.transaction do
      HomosaurusV2Subject.all.each do |subj|
        subj.destroy!
      end

      doc = File.open(xml_location) { |f| Nokogiri::XML(f) }

      doc.remove_namespaces!

      doc.xpath("//Concept").each do |concept|
        obj = {}
        obj[:label] = concept.xpath('./prefLabel').text.to_s
        obj[:identifier] = createIdentifier(obj[:label])

        obj[:alt_labels] = concept.xpath('./altLabel').map{ |l| l.text.to_s }
        obj[:related] = concept.xpath('./related').map{ |l| createIdentifier(l.text.to_s)}
        obj[:broader] = concept.xpath('./broader').map{ |l| createIdentifier(l.text.to_s)}
        obj[:narrower] = concept.xpath('./narrower').map{ |l| createIdentifier(l.text.to_s)}
        obj[:uri] = "http://homosaurus.org/v2/#{obj[:identifier]}"
        obj[:pid] = "homosaurus/v2/#{obj[:identifier]}"
        obj[:version] = "v2"
        obj[:description] = concept.xpath('./scopeNote').text

        existing = HomosaurusV2Subject.find_by(identifier: obj[:identifier])
        if existing.blank?
          HomosaurusV2Subject.create(obj)
        else
          existing.alt_labels = (existing.alt_labels + obj[:alt_labels]).uniq if obj[:alt_labels].present?
          existing.related = existing.related + obj[:related] if obj[:related].present?
          existing.broader = existing.broader + obj[:broader] if obj[:broader].present?
          existing.narrower = existing.narrower + obj[:narrower] if obj[:narrower].present?
          existing.description = existing.description if obj[:description].present?
          existing.save!
        end

      end
    end


    self.clean_all

  end

  def self.clean_all
    HomosaurusV2Subject.all.each do |subj|
      related = clean_up(subj.related)
      subj.related = related unless related == subj.related

      narrower = clean_up(subj.narrower)
      subj.narrower = narrower unless narrower == subj.narrower

      broader = clean_up(subj.broader)
      subj.broader = broader unless broader == subj.broader

      subj.save!
    end
  end

  def self.clean_up(array)
    values = []
    array.each do |rel|
      if HomosaurusV2Subject.exists?(identifier: rel)
        values << rel
      elsif HomosaurusV2Subject.exists?(identifier: rel[0..-2])
        values << rel[0..-2]
      end
    end
    values
  end

  def self.createIdentifier(s)
    match = HomosaurusSubject.find_by(label: s)
    return match.identifier if match.present?

    identifier = ''
    s.gsub(/[\(\)]*/, '').split(/[ \-]/).each_with_index do |t, index|
      if t.upcase == t
        identifier += t
      elsif index == 0
        identifier += t.downcase
      else
        identifier += t.capitalize
      end
    end
    identifier
  end

  def model_name
    "HomosaurusV2"
  end

  def remove_from_solr
    DSolr.delete_by_id "homosaurus/v2/#{self.identifier}"
  end

  def delete
    self.destroy
  end

  def send_solr
    doc = generate_solr_content
    DSolr.put doc
  end

  def generate_solr_content(doc={})
    doc[:id] = "homosaurus/v2/#{self.identifier}"
    doc[:system_create_dtsi] = "#{self.created_at.iso8601}"
    doc[:system_modified_dtsi] = "#{self.updated_at.iso8601}"
    doc[:model_ssi] = self.model_name
    doc[:has_model_ssim] = [self.model_name]
    doc[:date_created_tesim] = [self.created_at.iso8601.split('T')[0]]
    doc[:date_created_ssim] = doc[:date_created_tesim]
    doc[:issued_dtsi] = doc[:system_create_dtsi]
    doc[:modified_dtsi] = doc[:system_modified_dtsi]

    doc[:version_ssi] = self.version

    doc[:prefLabel_ssim] = [self.label]
    doc[:prefLabel_tesim] = doc[:prefLabel_ssim]
    doc[:broader_ssim] = self.broader
    doc[:related_ssim] = self.related
    doc[:narrower_ssim] = self.narrower
    doc[:closeMatch_ssim] = self.closeMatch
    doc[:exactMatch_ssim] = self.exactMatch
    doc[:altLabel_tesim] = self.alt_labels
    doc[:altLabel_ssim] = doc[:altLabel_tesim]
    doc[:identifier_ssi] = self.identifier
    doc[:description_ssi] = self.description
    doc[:description_tesim] = [self.description]

    doc[:dta_homosaurus_lcase_prefLabel_ssi] = self.label.downcase
    doc[:dta_homosaurus_lcase_altLabel_ssim] = []
    self.alt_labels.each do |alt|
      doc[:dta_homosaurus_lcase_altLabel_ssim] << alt.downcase
    end

    @broadest_terms = []
    get_broadest(self.identifier)
    doc[:topConcept_ssim] = @broadest_terms.uniq if @broadest_terms.present?
    doc[:new_model_ssi] = 'HomosaurusV2Subject'
    doc[:active_fedora_model_ssi] = 'HomosaurusV2'
    doc
  end

  def get_broadest(item)
    if HomosaurusV2Subject.find_by(identifier: item).broader.blank?
      @broadest_terms << item.split('/').last
    else
      puts 'FINDING FOR: ' + self.identifier.to_s
      HomosaurusV2Subject.find_by(identifier: item).broader.each do |current_broader|
        get_broadest(current_broader)
      end
    end
  end

  def verify_hierarchy(obj, type: 'broader')
    obj.send(type).each do |sub|
      HomosaurusV2Subject.find_by(identifier: sub).send(type).each do |sub2|
        return sub2 if sub2 == obj.identifier
      end
    end
    return nil
  end

  def verify_related(obj, type: 'related')
    match = false
    obj.send(type).each do |sub|
      HomosaurusV2Subject.find_by(identifier: sub).send(type).each do |sub2|
        match = true if sub2 == obj.identifier
      end
    end
    return obj.identifier unless match
    return nil
  end
end
