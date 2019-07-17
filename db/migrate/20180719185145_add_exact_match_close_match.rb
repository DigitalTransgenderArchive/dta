class AddExactMatchCloseMatch < ActiveRecord::Migration[5.1]
  def change
    unless ActiveRecord::Base.connection.table_exists?(:homosaurus_exactmatch_lcsh)
      change_table :homosaurus_subjects do |t|
        t.text :closeMatch_homosaurus
        t.text :exactMatch_homosaurus
      end

      create_table :homosaurus_exactmatch_lcsh do |t|
        t.belongs_to :homosaurus_subject
        t.belongs_to :lcsh_subject
      end
      add_index :homosaurus_exactmatch_lcsh, [:homosaurus_subject_id, :lcsh_subject_id], unique: true, name: 'index_homosaurus_exactmatch_lcsh_to_lcsh_subjects'

      create_table :homosaurus_closematch_lcsh do |t|
        t.belongs_to :homosaurus_subject
        t.belongs_to :lcsh_subject
      end
      add_index :homosaurus_closematch_lcsh, [:homosaurus_subject_id, :lcsh_subject_id], unique: true, name: 'index_homosaurus_closematch_lcsh_to_lcsh_subjects'

    end
  end
end