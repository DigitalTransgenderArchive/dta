class AddEnglishLabelToHomosaurus < ActiveRecord::Migration[5.1]
  def change
    unless ActiveRecord::Base.connection.column_exists?(:homosaurus_subjects, :label_eng)
      change_table :homosaurus_subjects do |t|
        t.string :label_eng
      end
    end
  end
end

=begin
create_table :homosaurus_lcsh_subjects do |t|
  t.belongs_to :homosaurus_subjects
  t.belongs_to :lcsh_subject
end
add_index :homosaurus_lcsh_subjects, [:homosaurus_subject_id, :lcsh_subject_id], unique: true, name: 'index_homosaurus_lcsh_subjects_to_lcsh_subjects'
=end
