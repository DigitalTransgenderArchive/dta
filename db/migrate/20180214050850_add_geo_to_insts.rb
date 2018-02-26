class AddGeoToInsts < ActiveRecord::Migration[5.2]
  def change
    unless ActiveRecord::Base.connection.column_exists?(:insts, :lat)
      add_column :insts, :lat, :decimal, {:precision=>10, :scale=>6}
      add_column :insts, :lng, :decimal, {:precision=>10, :scale=>6}
      add_index :insts, [ :lat, :lng ]
    end
  end
end
