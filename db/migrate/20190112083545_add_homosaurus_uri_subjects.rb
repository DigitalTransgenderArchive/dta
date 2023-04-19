class AddHomosaurusUriSubjects < ActiveRecord::Migration[5.1]
  def change
    unless ActiveRecord::Base.connection.table_exists?(:homosaurus_uri_subjects)
      create_table :object_homosaurus_uri_subjects do |t|
        t.belongs_to :generic_object, index: { name: 'homosaurus_uri_to_obj_index2' }
        t.belongs_to :homosaurus_uri_subject, index: { name: 'obj_to_homosaurus_uri_index2' }
      end
      add_index(:object_homosaurus_uri_subjects, [:generic_object_id, :homosaurus_uri_subject_id], unique: true, name: 'index_object_to_homosaurus_uri_subject')

      create_table :homosaurus_uri_subjects do |t|
        t.string :uri, index: { unique: true }
        t.string :label

        # Serialized data
        t.text :language_labels
        t.text :alt_labels
        t.text :broader
        t.text :narrower
        t.text :related
      end
    end
  end
end
