class UpgradeHomosaurus
  def perform_upgrade
    duplicates = []
    weird_cases = []
    upgrade_lookup = {}
    HomosaurusV2Subject.all.each do |homo|
      count = 0
      homo.exactMatch_homosaurus.each do |exactMatch|
        exactMatchRecord = HomosaurusSubject.find_by(uri: exactMatch)
        count = count + 1
        upgrade_lookup[exactMatchRecord.id] ||= []
        upgrade_lookup[exactMatchRecord.id] << homo.id
        if exactMatchRecord.label.downcase != homo.label.downcase
          weird_cases << "[" + exactMatchRecord.label + "] [" + homo.label + "]"
        end

        if count > 1
          duplicates << homo.id
        end
      end
    end
    weird_cases.uniq!

    ActiveRecord::Base.transaction do
      GenericObject.all.each do |obj|
        subjects_to_remove = []
        subjects_to_add = []
        current_v1_subjects = obj.homosaurus_subjects
        current_v1_subjects.each do |subj|
          if upgrade_lookup[subj.id].present?
            upgrade_lookup[subj.id].each do |related_subj_id|
              subjects_to_add += [HomosaurusV2Subject.find(related_subj_id)]
            end
            subjects_to_remove << subj
          end
        end
        if subjects_to_add.present?
          obj.homosaurus_subjects = current_v1_subjects - subjects_to_remove
          obj.homosaurus_v2_subjects = subjects_to_add
          obj.save!
        end
        obj.generate_solr_content
      end
    end
  end

end