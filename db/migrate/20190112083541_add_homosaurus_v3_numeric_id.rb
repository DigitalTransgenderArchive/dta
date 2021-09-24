class AddHomosaurusV3NumericId < ActiveRecord::Migration[5.1]
  def change
    unless ActiveRecord::Base.connection.column_exists?(:homosaurus_subjects, :numeric_pid)
      change_table :homosaurus_subjects do |t|
        t.integer  :numeric_pid
      end
    end
  end
end
