class AddHomosaurusV3LanguageSupport < ActiveRecord::Migration[5.1]
  def change
    unless ActiveRecord::Base.connection.column_exists?(:homosaurus_subjects, :language_labels)
      change_table :homosaurus_subjects do |t|
        t.string  :language_labels
      end
    end
  end
end
