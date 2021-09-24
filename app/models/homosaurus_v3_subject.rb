class HomosaurusV3Subject < HomosaurusSubject
  include HomosaurusAssignments
  after_save :send_solr

  def self.find_with_conditions(q:, rows:, fl:)
    opts = {}
    opts[:q] = q
    opts[:fl] = fl
    opts[:rows] = rows
    opts[:fq] = 'active_fedora_model_ssi:HomosaurusV3'
    result = DSolr.find(opts)
    result
  end

  def terms
    ['closeMatch', 'exactMatch']
  end

  def self.mint_old
    conflicts = true
    while conflicts do
      pid = SecureRandom.hex[0..6]
      conflicts = false unless HomosaurusV3Subject.exists?(identifier: pid)
    end
    return pid
  end

  def self.mint
    numeric_pid = HomosaurusV3Subject.maximum(:numeric_pid) || 1
    numeric_pid
  end

  def self.loadV3Part1
    ActiveRecord::Base.transaction do
      HomosaurusV3Subject.all.each do |subj|
        subj.destroy!
      end

      counter = 1

      HomosaurusV2Subject.all.each do |v2_subj|
        obj = HomosaurusV3Subject.new
        obj.label = v2_subj.label
        obj.label_eng = v2_subj.label_eng
        obj.numeric_pid = counter
        obj.identifier = "homoit" + obj.numeric_pid.to_s.rjust(7, '0')
        counter+=1
        #HomosaurusV3Subject.mint
        obj.alt_labels = v2_subj.alt_labels
        obj.replaces = v2_subj.uri
        obj.uri = "https://homosaurus.org/v3/#{obj[:identifier]}"
        obj.pid = "homosaurus/v3/#{obj[:identifier]}"
        obj.exactMatch_lcsh = v2_subj.exactMatch_lcsh.map(&:uri)
        obj.closeMatch_lcsh = v2_subj.closeMatch_lcsh.map(&:uri)
        obj.version = "v3"
        obj[:description] = v2_subj.description
        obj.save!

      end
    end
  end

  def self.loadV3Part2
    ActiveRecord::Base.transaction do
      HomosaurusV3Subject.all.each do |v3_subj|
        v2_obj = HomosaurusV2Subject.find_by(uri: v3_subj.replaces)
        new_related = []
        v2_obj.related.each do |item|
          new_related << HomosaurusV3Subject.find_by(replaces: "http://homosaurus.org/v2/#{item}").identifier
        end
        v3_subj.related = new_related

        new_narrower = []
        v2_obj.narrower.each do |item|
          new_narrower << HomosaurusV3Subject.find_by(replaces: "http://homosaurus.org/v2/#{item}").identifier
        end

        new_broader = []
        v2_obj.broader.each do |item|
          new_broader << HomosaurusV3Subject.find_by(replaces: "http://homosaurus.org/v2/#{item}").identifier
        end
        v3_subj.related = new_related
        v3_subj.broader = new_broader
        v3_subj.narrower = new_narrower
        v3_subj.save!

        v2_obj.isReplacedBy = v3_subj.uri
        v2_obj.save!
      end
    end
  end

  def self.upload_lcsh(spreadsheet_location)
    ActiveRecord::Base.transaction do
      if spreadsheet_location =~ /\b.xlsx$\b/
        worksheet = Roo::Excelx.new(spreadsheet_location)
      elsif spreadsheet_location =~ /\b.xls$\b/
        worksheet = Roo::Excel.new(spreadsheet_location)
      elsif spreadsheet_location =~ /\b.csv\b/
        worksheet = Roo::CSV.new(spreadsheet_location)
      elsif spreadsheet_location =~ /\b.ods\b/
        worksheet = Roo::OpenOffice.new(spreadsheet_location)
      end
      worksheet.default_sheet = worksheet.sheets.first #Sets to the first sheet in the workbook

      data_start_row = 2
      data_start_row.upto worksheet.last_row do |index|
        row = worksheet.row(index)
        if row.present?
          #begin
            identifier = strip_value(row[1])
            lcsh_possibility = strip_value(row[3])

            if identifier.present? and lcsh_possibility.present? and lcsh_possibility.starts_with?('http://id.loc.gov/authorities/subjects/')
              subject = HomosaurusV3Subject.find_by(identifier: identifier)
              if subject.present?
                if subject.exactMatch_lcsh.blank?
                  subject.exactMatch_lcsh = lcsh_possibility
                  subject.save!
                end
              else
                raise "No Homosaurus Subject Found for Identifier: #{identifier.to_s}"
              end
            end
          #rescue Exception => e
            #Exception handling for when encounter bad data...
          #end
        end
      end
    end
  end

  def self.strip_value(value)
    if value.nil?
      return nil
    else
      if value.class == Float
        value = value.to_f.to_s
        value = value.gsub(/.0$/, '') #FIXME: Temporary. Bugged as see: https://github.com/roo-rb/roo/issues/86 , https://github.com/roo-rb/roo/issues/133 , https://github.com/zdavatz/spreadsheet/issues/41
      elsif value.class == Fixnum
        value = value.to_i.to_s #FIXME: to_i as otherwise non-existant values cause problems
      end
      # Make sure it is all UTF-8 and not character encodings or HTML tags and remove any cariage returns
      return utf8Encode(value)
    end
  end

  def self.utf8Encode(value)
    #return HTMLEntities.new.decode(ActionView::Base.full_sanitizer.sanitize(value.to_s.gsub(/\r?\n?\t/, ' ').gsub(/\r?\n/, ' '))).strip
    return value.to_s.gsub(/\r?\n?\t/, ' ').gsub(/\r?\n/, ' ').strip
  end

  def model_name
    "HomosaurusV3"
  end

  def remove_from_solr
    DSolr.delete_by_id "homosaurus/v3/#{self.identifier}"
  end

  def delete
    self.destroy
  end

  def send_solr
    doc = generate_solr_content
    DSolr.put doc
  end

  def generate_solr_content(doc={})
    doc[:id] = "homosaurus/v3/#{self.identifier}"
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
    doc[:label_eng_ssim] = [self.label_eng]
    doc[:label_eng_tesim] = doc[:label_eng_ssim]
    doc[:broader_ssim] = self.broader
    doc[:related_ssim] = self.related
    doc[:narrower_ssim] = self.narrower
    doc[:closeMatch_ssim] = self.closeMatch
    doc[:exactMatch_ssim] = self.exactMatch
    doc[:isReplacedBy_ssim] = [self.isReplacedBy]
    doc[:replaces_ssim] = [self.replaces]
    doc[:altLabel_tesim] = self.alt_labels
    doc[:altLabel_ssim] = doc[:altLabel_tesim]
    doc[:identifier_ssi] = self.identifier
    doc[:description_ssi] = self.description
    doc[:description_tesim] = [self.description]

    doc[:exactMatch_ssim] = self.exactMatch_homosaurus.dup
    self.exactMatch_lcsh.each do |l|
      doc[:exactMatch_ssim] << l.uri
    end

    doc[:closeMatch_ssim] = self.closeMatch_homosaurus.dup
    self.closeMatch_lcsh.each do |l|
      doc[:closeMatch_ssim] << l.uri
    end

    doc[:dta_homosaurus_lcase_prefLabel_ssi] = self.label.downcase
    doc[:dta_homosaurus_lcase_altLabel_ssim] = []
    self.alt_labels.each do |alt|
      doc[:dta_homosaurus_lcase_altLabel_ssim] << alt.downcase
    end

    @broadest_terms = []
    get_broadest(self.identifier)
    doc[:topConcept_ssim] = @broadest_terms.uniq if @broadest_terms.present?
    doc[:new_model_ssi] = 'HomosaurusV3Subject'
    doc[:active_fedora_model_ssi] = 'HomosaurusV3'
    doc
  end

  def get_broadest(item)
    if HomosaurusV3Subject.find_by(identifier: item).broader.blank?
      @broadest_terms << item.split('/').last
    else
      HomosaurusV3Subject.find_by(identifier: item).broader.each do |current_broader|
        get_broadest(current_broader)
      end
    end
  end

  def verify_hierarchy(obj, type: 'broader')
    obj.send(type).each do |sub|
      HomosaurusV3Subject.find_by(identifier: sub).send(type).each do |sub2|
        return sub2 if sub2 == obj.identifier
      end
    end
    return nil
  end

  def verify_related(obj, type: 'related')
    match = false
    obj.send(type).each do |sub|
      HomosaurusV3Subject.find_by(identifier: sub).send(type).each do |sub2|
        match = true if sub2 == obj.identifier
      end
    end
    return obj.identifier unless match
    return nil
  end


  def self.show_fields
    ['prefLabel', 'label@en_us', 'altLabel', 'description', 'identifier', 'issued', 'modified', 'exactMatch', 'closeMatch']
  end

  def self.get_values(field, obj)
    case field
    when "identifier"
      [obj["identifier_ssi"]] || []
    when "prefLabel"
      obj["prefLabel_ssim"] || []
    when "label@en_us"
      obj["label_eng_ssim"] || []
    when "altLabel"
      obj["altLabel_ssim"] || []
    when "description"
      [obj["description_ssi"]] || []
    when "issued"
      obj["date_created_ssim"] || []
    when "modified"
      obj["date_created_ssim"] || []
    when "exactMatch"
      obj["exactMatch_ssim"] || []
    when "closeMatch"
      obj["closeMatch_ssim"] || []
    when "related"
      obj["related_ssim"] || []
    when "broader"
      obj["broader_ssim"] || []
    when "narrower"
      obj["narrower_ssim"] || []
    else
      [nil]
    end
  end

  def self.getLabel field
    case field
    when "identifier"
      "<a href='http://purl.org/dc/terms/identifier' target='blank' title='Definition of Identifier in the Dublin Core Terms Vocabulary'>Identifier</a>"
    when "prefLabel"
      "<a href='http://www.w3.org/2004/02/skos/core#prefLabel' target='blank'  title='Definition of Preferred Label in the SKOS Vocabulary'>Preferred Label</a>"
    when "label@en_us"
      "<a href='https://terms.tdwg.org/wiki/rdfs:label' target='blank'  title='RDFS label property with the english language flag.'>US English Label</a>"
    when "altLabel"
      "<a href='http://www.w3.org/2004/02/skos/core#altLabel' target='blank'  title='Definition of Alternative Label in the SKOS Vocabulary'>Alternative Label (Use For)</a>"
    when "description"
      "<a href='http://www.w3.org/2000/01/rdf-schema#comment' target='blank'  title='Definition of Comment in the RDF Schema Vocabulary'>Description</a>"
    when "issued"
      "<a href='http://purl.org/dc/terms/issued' target='blank'  title='Definition of Issued in the Dublin Core Terms Vocabulary'>Issued (Created)</a>"
    when "modified"
      "<a href='http://purl.org/dc/terms/modified' target='blank'  title='Definition Modified in the Dublin Core Terms Vocabulary'>Modified</a>"
    when "exactMatch"
      "<a href='http://www.w3.org/2004/02/skos/core#exactMatch' target='blank'  title='Definition of exactMatch in the SKOS Vocabulary'>External Exact Match</a>"
    when "closeMatch"
      "<a href='http://www.w3.org/2004/02/skos/core#closeMatch' target='blank'  title='Definition of Modified in the SKOS Vocabulary'>External Close Match</a>"
    when "related"
      "<a href='http://www.w3.org/2004/02/skos/core#related' target='blank'  title='Definition of Related in the SKOS Vocabulary'>Related Terms</a>"
    when "broader"
      "<a href='http://www.w3.org/2004/02/skos/core#broader' target='blank'  title='Definition of Broader in the SKOS Vocabulary'>Broader Terms</a>"
    when "narrower"
      "<a href='http://www.w3.org/2004/02/skos/core#narrower' target='blank'  title='Definition of Narrower in the SKOS Vocabulary'>Narrower Terms</a>"
    else
      field.humanize
    end
  end

end
