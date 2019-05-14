class FixHomosaurus
  include Sidekiq::Worker
  sidekiq_options unique: :until_and_while_executing

  def perform
    terms = HomosaurusV2Subject.all

    ActiveRecord::Base.transaction do
      dup_fix = HomosaurusV2Subject.where("pid like ?", "homosaurus/v2/organisationsForSexualResearchAndSexual%")
      original_identifier

      terms.each do |term|
        if term.identifier.include?("'") || term.identifier.include?(";")  || term.identifier.include?('"') || term.identifier.include?("á") || term.identifier.include?("\n") || term.identifier.include?("\t") || term.identifier.length > 34
          term.remove_from_solr

          original_identifier = term.identifier

          new_identifier = term.identifier.gsub(/['";\n\t]+/, '').gsub("á", "a")
          if new_identifier.include?('MRKHMullerian')
            new_identifier = 'MRKH'
          elsif new_identifier.length > 34
            new_identifier = new_identifier[0..35]
          end


          term.identifier = new_identifier
          term.uri = "http://homosaurus.org/v2/#{new_identifier}"
          term.pid = "homosaurus/v2/#{new_identifier}"
          term.save!

          broader = HomosaurusV2Subject.where("broader like ?", "%#{original_identifier}%")
          broader.each do |rel|
            if rel.broader.include?(original_identifier)
              rel.broader.delete(original_identifier)
              rel.broader << new_identifier
              rel.save!
            end
          end

          narrower = HomosaurusV2Subject.where("narrower like ?", "%#{original_identifier}%")
          narrower.each do |rel|
            if rel.narrower.include?(original_identifier)
              rel.narrower.delete(original_identifier)
              rel.narrower << new_identifier
              rel.save!
            end
          end

          related = HomosaurusV2Subject.where("related like ?", "%#{original_identifier}%")
          related.each do |rel|
            if rel.related.include?(original_identifier)
              rel.related.delete(original_identifier)
              rel.related << new_identifier
              rel.save!
            end
          end

          term.send_solr
        end

      end
    end
  end
end
