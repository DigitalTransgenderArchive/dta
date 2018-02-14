class CreatePosts < ActiveRecord::Migration[4.2]
  def change
    create_table :posts do |t|
      t.string :title, null: false
      t.string :slug, null: false
      t.text :content
      t.text :abstract
      t.boolean :published
      t.string :created_ym
      t.string :created_ymd
      t.string :thumbnail
      t.datetime :created
      t.datetime :updated
      t.string :user

      t.timestamps null: false
    end

    add_index :posts, :slug, unique: true
    add_index :posts, :created
  end
end
