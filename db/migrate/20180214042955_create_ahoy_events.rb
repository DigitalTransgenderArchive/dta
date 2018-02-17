class CreateAhoyEvents < ActiveRecord::Migration[5.2]
  def change
    create_table :ahoy_events do |t|
      t.integer :visit_id

      # user
      t.integer :user_id
      # add t.string :user_type if polymorphic

      t.string :param1
      t.string :param1_type
      t.string :param2
      t.string :param2_type
      t.string :pid, limit: 64
      t.string :collection_pid, limit: 64
      t.string :institution_pid, limit: 64
      t.string :model, limit: 128
      t.string :search_term
      t.string :name
      t.text :properties
      t.timestamp :time
    end

    add_index :ahoy_events, [:visit_id, :name]
    add_index :ahoy_events, [:user_id, :name]
    add_index :ahoy_events, [:name, :time]
  end
end
