class AddHomosaurusV3ToGenericObject < ActiveRecord::Migration[5.1]
  def change
    unless ActiveRecord::Base.connection.table_exists?(:object_homosaurus_v3_subjects)
      change_table :homosaurus_subjects do |t|
        t.string :isReplacedBy
        t.string :replaces
      end

      create_table :object_homosaurus_v3_subjects do |t|
        t.belongs_to :generic_object
        t.belongs_to :homosaurus_v3_subject
      end
      add_index :object_homosaurus_v3_subjects, [:generic_object_id, :homosaurus_v3_subject_id], unique: true, name: 'index_object_homosaurus_v2_subjects_go_homosaurus_subjects'

    end
  end
end
