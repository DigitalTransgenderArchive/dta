class CreateLearns < ActiveRecord::Migration[4.2]
  def change
    create_table :learns do |t|
      t.string :url_label
      t.string :title
      t.integer :link_order
      t.text :content
      t.string :styletype
      t.boolean :published

      t.timestamps null: false
    end
    add_index :learns, :url_label, unique: true
    add_index :learns, :link_order
    add_index :learns, :published
  end
end
