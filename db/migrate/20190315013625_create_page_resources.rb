class CreatePageResources < ActiveRecord::Migration[4.2]
  def change
    unless ActiveRecord::Base.connection.table_exists?(:page_resources)
      create_table :page_resources do |t|
        t.string :url_label
        t.string :title
        t.integer :link_order
        t.text :content
        t.string :styletype
        t.boolean :published

        t.timestamps null: false
      end
      add_index :page_resources, :url_label, unique: true
      add_index :page_resources, :link_order
      add_index :page_resources, :published
    end
  end
end
