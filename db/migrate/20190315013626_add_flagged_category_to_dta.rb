class AddFlaggedCategoryToDta < ActiveRecord::Migration[5.2]
  def change
    unless ActiveRecord::Base.connection.column_exists?(:generic_objects, :flagged_category)
      change_table :generic_objects do |t|
        t.text :flagged_category, null: true
      end
    end
  end
end
