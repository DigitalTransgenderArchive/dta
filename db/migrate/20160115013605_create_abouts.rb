class CreateAbouts < ActiveRecord::Migration[4.2]
  def change
    create_table :abouts do |t|
      t.string :url_label
      t.string :title
      t.integer :link_order
      t.text :content
      t.string :styletype
      t.boolean :published

      t.timestamps null: false
    end
    add_index :abouts, :url_label, unique: true
    add_index :abouts, :link_order
    add_index :abouts, :published
  end
end
