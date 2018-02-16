class Upgrade

  def self.upgrade
    Upgrade.upgrade_institutions

    Upgrade.upgrade_collections

    Upgrade.upgrade_homosaurus

    Upgrade.upgrade_objects

    Upgrade.upgrade_collection_images

    #Upgrade.send_solr
  end

  def self.send_solr
    Inst.all.each do |inst|
      inst.send_solr
    end

    Coll.all.each do |coll|
      coll.send_solr
    end

    HomosaurusSubject.all.each do |subj|
      subj.send_solr
    end

    GenericObject.all.each do |file|
      file.send_solr
    end
  end

  def self.upgrade_institutions
    Institution.all.each do |old_inst|
      unless Inst.find_by(pid: old_inst.id).present?
        inst = Inst.new(pid: old_inst.id)

        inst.created_at = old_inst.date_created.to_date
        inst.name = old_inst.name
        inst.description = old_inst.description
        inst.contact_person = old_inst.contact_person
        inst.description = old_inst.description
        inst.address = old_inst.address
        inst.email = old_inst.email
        inst.phone = old_inst.phone
        inst.institution_url = old_inst.institution_url
        inst.visibility = 'public'

        if old_inst.content.present?
          inst.add_image(old_inst.content.content, old_inst.content.mime_type)
        end

        #geo_result = Geonames.search(old_inst.name.split(',').last.strip, 'S')
        #if geo_result.present?
        #inst.geonames = geo_result.first["uri_link"]
        #end

        inst.save!
      end
    end
  end

  def self.upgrade_collections
    Collection.all.each do |old_collection|
      unless Coll.find_by(pid: old_collection.id).present?
        coll = Coll.new(pid: old_collection.id)

        coll.created_at = old_collection.date_created[0].to_date
        coll.depositor = old_collection.depositor
        coll.title = old_collection.title
        coll.description = old_collection.description
        coll.pid = old_collection.id

        solr_content = DSolr.solr_by_id old_collection.id
        if solr_content["is_public_ssi"] == "true"
          coll.visibility = "public"
        else
          coll.visibility = "private"
        end

        old_collection.institutions.each do |old_inst|
          inst = Inst.find_by(pid: old_inst.id)
          coll.insts << inst
        end

        coll.save!
      end
    end
  end

  def self.upgrade_collection_images
    Collection.all.each do |old_collection|
        coll = Coll.find_by(pid: old_collection.id)
        unless coll.base_file.present? || old_collection.thumbnail_ident.blank?
          coll.generic_object = GenericObject.find_by(pid: old_collection.thumbnail_ident)
          coll.save!
        end
    end
  end

  def self.upgrade_homosaurus
    Homosaurus.all.each do |old_homo|
      unless HomosaurusSubject.find_by(identifier: old_homo.identifier).present?
        homo = HomosaurusSubject.new
        homo.uri = "http://homosaurus.org/terms/#{old_homo.identifier}"
        homo.identifier = old_homo.identifier
        homo.label = old_homo.prefLabel
        homo.version = "v1"
        homo.description = old_homo.description
        homo.created_at = old_homo.issued.to_date
        homo.updated_at = old_homo.modified.to_date
        homo.alt_labels = old_homo.altLabel.to_a
        homo.broader.each do |obj|
          homo.broader << obj.identifier
        end
        homo.narrower.each do |obj|
          homo.narrower << obj.identifier
        end
        homo.related.each do |obj|
          homo.related << obj.identifier
        end
        homo.closeMatch = old_homo.closeMatch.to_a
        homo.exactMatch = old_homo.exactMatch.to_a
        homo.save!
      end
    end
  end

  def self.upgrade_objects
    GenericFile.find_each do |file|
      Upgrade.upgrade_object(file)
    end
  end

  def self.upgrade_users
    OldUser.find_in_batches.each do |old_users|
      old_users.each do |old_user|
        unless old_user.email.starts_with? 'guest_' || User.find_by(email: old_user.email).present?
          User.create(id: old_user.id, email: old_user.email, encrypted_password: old_user.encrypted_password, created_at: old_user.created_at )
        end
      end
    end
  end

  def self.upgrade_object(file)
    unless GenericObject.find_by(pid: file.id).present?
      obj = GenericObject.new(pid: file.id)
      raise "No Institution For #{file.id}" if file.institutions.blank?
      obj.inst = Inst.find_by(pid: file.institutions.first.id)
      raise "No Collection For #{file.id}" if file.collections.blank?
      obj.coll = Coll.find_by(pid: file.collections.first.id)
      obj.title = file.title[0]
      obj.toc = file.toc
      obj.analog_format = file.analog_format
      obj.digital_format = file.digital_format
      obj.flagged = file.flagged
      obj.is_shown_at = file.is_shown_at
      obj.preview = file.preview
      obj.hosted_elsewhere = file.hosted_elsewhere
      obj.hosted_elsewhere ||= "0"
      obj.identifier = file.identifier[0]
      obj.depositor = file.depositor
      #obj.visibility
      obj.descriptions = file.description.to_a
      obj.temporal_coverage = file.temporal_coverage.to_a
      obj.date_created = file.date_created.to_a
      obj.date_issued = file.date_issued.to_a
      obj.alt_titles = file.alternative.to_a
      obj.publishers = file.publisher.to_a
      obj.related_urls = file.related_url.to_a
      obj.rights_free_text = file.rights_free_text.to_a
      obj.languages = file.language.to_a

      # has_many
      o_subjs = []
      h_subjs = []
      l_subjs = []
      file.subject.each do |subj|
        if subj.present?
          if subj.include?('http://id.loc.gov')
            l_subjs << subj
          elsif subj.include?('http://homosaurus.org/terms')
            h_subjs << subj
          else
            o_subjs << subj
          end
        end
      end
      obj.other_subjects = o_subjs
      obj.lcsh_subjects = l_subjs
      obj.homosaurus_subjects = h_subjs

      obj.creators = file.creator.to_a
      obj.contributors = file.contributor.to_a
      obj.genres = file.genre.to_a
      obj.resource_types = file.resource_type.to_a
      obj.rights = file.rights.to_a
      obj.geonames = file.based_near.to_a

      #open
      #restricted
      solr_content = DSolr.solr_by_id file.id
      if solr_content["visibiliy_ssi"] == "open"
        obj.visibility = "public"
      elsif solr_content["visibiliy_ssi"] == "restricted"
        obj.visibility = "private"
      elsif solr_content["visibiliy_ssi"].present?
        obj.visibility = "hidden"
      end
      obj.created_at = solr_content["system_create_dtsi"].to_datetime
      obj.updated_at = solr_content["system_modified_dtsi"].to_datetime

      if file.content.present?
        if file.content.mime_type.starts_with?('application/pdf')
          obj.add_pdf(file.content.content, file.content.mime_type)
        elsif file.content.mime_type.starts_with?('image')
          obj.add_image(file.content.content, file.content.mime_type)
        elsif file.content.mime_type.starts_with?('application/vnd.openxmlformats-officedocument.wordprocessingml.document')
          obj.add_document(file.content.content, file.content.mime_type)
        elsif file.content.mime_type.starts_with?('application/msword')
          obj.add_document(file.content.content, file.content.mime_type)
        else
          raise "Unkown content type for: #{file.id}"
        end

        if obj.hosted_elsewhere == "1"
          obj.base_files.first.low_res = true
        end
        obj.base_files.first.fedora_imported = true

        if file.ocr.present?
          if file.ocr.content.encoding.to_s == "ASCII-8BIT"
            obj.base_files.first.ocr = file.ocr.content.force_encoding("UTF-8")
          elsif file.ocr.content.encoding.to_s == 'UTF-8'
            obj.base_files.first.ocr = file.ocr.content
          else
            raise 'Find encoding for: ' + file.id
          end
          obj.base_files.first.original_ocr = obj.base_files.first.ocr
        end

        if file.characterization.present?
          if file.characterization.content.encoding.to_s == "ASCII-8BIT"
            obj.base_files.first.fits = file.characterization.content.force_encoding("UTF-8")
          elsif file.characterization.content.encoding.to_s == 'UTF-8'
            obj.base_files.first.fits = file.characterization.content
          else
            raise 'Find encoding for FITS: ' + file.id
          end
        end

        if file.thumbnail.present?
          # FIXME: Create is broken with this approach...
          thumb = ThumbnailDerivative.new(base_file: obj.base_files.first, mime_type: 'image/jpeg')
          thumb.content = file.thumbnail.content
          thumb.save!
        end

      end

      obj.save!
    end
  end

end
