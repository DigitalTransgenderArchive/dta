class AddTypeToHomosaurus < ActiveRecord::Migration[5.1]
  def change
    unless ActiveRecord::Base.connection.column_exists?(:homosaurus_subjects, :type)
      change_table :homosaurus_subjects do |t|
        t.string :type, null: false, default: 'HomosaurusSubject'
      end
    end

    if index_exists? :homosaurus_subjects, [:identifier]
      remove_index :homosaurus_subjects, :identifier
      add_index :homosaurus_subjects, [:identifier, :version], unique: true
      add_index :homosaurus_subjects, [:identifier, :type], unique: true
    end
  end
end

