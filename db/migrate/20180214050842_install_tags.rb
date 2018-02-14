class InstallTags < ActiveRecord::Migration[5.2]
  def change
   unless ActiveRecord::Base.connection.table_exists?(:tags)
      create_table :tags do |t|
        t.string :name
      end

      create_table :taggings do |t|
        t.references :tag

        # You should make sure that the column created is
        # long enough to store the required class names.
        t.references :taggable, polymorphic: true
        t.references :tagger, polymorphic: true

        # Limit is created to prevent MySQL error on index
        # length for MyISAM table type: http://bit.ly/vgW2Ql
        t.string :context, limit: 128

        t.datetime :created_at
      end

      unless index_exists? :taggings, [:tag_id]
        add_index :taggings, :tag_id
      end
      add_index :taggings, [:taggable_id, :taggable_type, :context]

      add_index :tags, :name, unique: true

      remove_index :taggings, :tag_id if index_exists?(:taggings, :tag_id)
      remove_index :taggings, [:taggable_id, :taggable_type, :context]
      add_index :taggings,
                [:tag_id, :taggable_id, :taggable_type, :context, :tagger_id, :tagger_type],
                unique: true, name: 'taggings_idx'

      add_column :tags, :taggings_count, :integer, default: 0

      ActsAsTaggableOn::Tag.reset_column_information
      ActsAsTaggableOn::Tag.find_each do |tag|
        ActsAsTaggableOn::Tag.reset_counters(tag.id, :taggings)
      end

      add_index :taggings, [:taggable_id, :taggable_type, :context]

      if ActsAsTaggableOn::Utils.using_mysql?
        execute("ALTER TABLE tags MODIFY name varchar(255) CHARACTER SET utf8 COLLATE utf8_bin;")
      end

      add_index :taggings, :tag_id unless index_exists? :taggings, :tag_id
      add_index :taggings, :taggable_id unless index_exists? :taggings, :taggable_id
      add_index :taggings, :taggable_type unless index_exists? :taggings, :taggable_type
      add_index :taggings, :tagger_id unless index_exists? :taggings, :tagger_id
      add_index :taggings, :context unless index_exists? :taggings, :context

      unless index_exists? :taggings, [:tagger_id, :tagger_type]
        add_index :taggings, [:tagger_id, :tagger_type]
      end

      unless index_exists? :taggings, [:taggable_id, :taggable_type, :tagger_id, :context], name: 'taggings_idy'
        add_index :taggings, [:taggable_id, :taggable_type, :tagger_id, :context], name: 'taggings_idy'
      end
    end
  end
end