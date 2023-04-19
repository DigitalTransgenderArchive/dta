class AddHomosaurusV3PreflabelLanguage < ActiveRecord::Migration[5.1]
  def change
    unless ActiveRecord::Base.connection.column_exists?(:homosaurus_subjects, :prefLabel_language)
      change_table :homosaurus_subjects do |t|
        t.string  :prefLabel_language
      end
    end
  end
end
