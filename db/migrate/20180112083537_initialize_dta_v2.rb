class InitializeDtaV2 < ActiveRecord::Migration[5.1]
  def change
    unless ActiveRecord::Base.connection.table_exists?(:generic_objects)

      create_table :insts do |t|
        t.string :pid, index: { unique: true }, limit: 64
        t.string :name, index: { unique: true }
        t.text :description
        t.string :contact_person
        t.string :address
        t.string :email
        t.string :phone
        t.string :institution_url
        t.string :visibility, limit: 50

        # Need to handle file upload
        #t.string :inst_image_id
        #t.string :inst_image_filename
        #t.string :inst_image_content_size
        #t.string :inst_image_content_type

        t.belongs_to :geonames

        t.integer :views, :null => false, :default => 0
        t.timestamps null: false
      end

      create_table :inst_colls do |t|
        t.belongs_to :inst
        t.belongs_to :coll
      end
      add_index :inst_colls, [:inst_id, :coll_id], unique: true

      # Collections can belong to many institutions?
      create_table :colls do |t|
        #t.references :insts
        t.string :pid, index: { unique: true }, limit: 64
        t.string :title, index: { unique: true }
        t.text :description
        t.string :depositor
        t.string :visibility, limit: 50
        t.belongs_to :generic_object # Essentially what object to steal an image from
        t.belongs_to :inst
        #t.references :generic_objects
        t.timestamps null: false
        t.integer :views, :null => false, :default => 0
      end

      create_table :generic_objects do |t|
        t.string :pid, index: { unique: true }, limit: 64
        t.string :title, limit: 355
        t.text :toc
        t.string :analog_format
        t.string :digital_format
        t.string :flagged
        t.string :is_shown_at
        t.string :preview
        t.string :hosted_elsewhere, limit: 10
        t.string :identifier

        t.string :depositor
        t.string :visibility, limit: 50

        # These are serialized arrays. Used for display data mainly. May change in the future.
        t.text :descriptions
        t.text :temporal_coverage
        t.text :date_issued
        t.text :date_created
        t.text :alt_titles
        t.text :publishers
        t.text :related_urls
        t.text :rights_free_text
        t.text :languages

        t.timestamps null: false
        t.integer :views, :null => false, :default => 0
        t.integer :downloads, :null => false, :default => 0

        t.belongs_to :inst
        t.belongs_to :coll
      end

      create_table :object_genres do |t|
        t.belongs_to :generic_object
        t.belongs_to :genre
      end
      add_index :object_genres, [:generic_object_id, :genre_id], unique: true, name: 'index_object_genre_to_genre'

      create_table :genres do |t|
        t.string :label, index: { unique: true }
      end

      create_table :object_resource_types do |t|
        t.belongs_to :generic_object
        t.belongs_to :resource_type
      end
      add_index :object_resource_types, [:generic_object_id, :resource_type_id], unique: true, name: 'index_object_resource_types_to_resource_types'

      create_table :resource_types do |t|
        t.string :label, index: { unique: true }
        t.string :uri, index: { unique: true }
      end

      create_table :object_rights do |t|
        t.belongs_to :generic_object
        t.belongs_to :rights
      end
      add_index :object_rights, [:generic_object_id, :rights_id], unique: true, name: 'index_object_rights_to_rights'

      create_table :rights do |t|
        t.string :label, index: { unique: true }
        t.string :uri
      end

     # Use STI for all of these? Still need to do language...
      create_table :object_lcsh_subjects do |t|
        t.belongs_to :generic_object
        t.belongs_to :lcsh_subject
      end
      add_index :object_lcsh_subjects, [:generic_object_id, :lcsh_subject_id], unique: true, name: 'index_object_lcsh_subjects_go_lcsh_subjects'

      # Missing Hierarchy
      create_table :lcsh_subjects do |t|
        t.string :uri, index: { unique: true }
        t.string :label

        # Serialized data
        t.text :alt_labels
        t.text :broader
        t.text :narrower
        t.text :related
      end

      create_table :object_homosaurus_subjects do |t|
        t.belongs_to :generic_object
        t.belongs_to :homosaurus_subject
      end
      add_index :object_homosaurus_subjects, [:generic_object_id, :homosaurus_subject_id], unique: true, name: 'index_object_homosaurus_subjects_go_homosaurus_subjects'

     # Missing Hierarchy
      create_table :homosaurus_subjects do |t|
        t.string :uri, index: { unique: true }
        t.string :identifier, index: { unique: true }
        t.string :label
        t.string :version
        t.text :description
        t.timestamps null: false
        # Serialized data
        t.text :alt_labels
        t.text :broader
        t.text :narrower
        t.text :related
        t.text :closeMatch
        t.text :exactMatch
      end

      create_table :geonames do |t|
        t.string :uri, index: { unique: true }
        t.string :label
        t.string :lat
        t.string :lng
        # Serialized data
        t.text :alt_labels
        t.text :hierarchy_full
        t.text :hierarchy_display

        # Special Serialized data
        t.text :geo_json_hash
      end

      create_table :object_geonames do |t|
        t.belongs_to :generic_object
        t.belongs_to :geoname
      end
      add_index :object_geonames, [:generic_object_id, :geoname_id], unique: true

      create_table :other_subjects do |t|
        t.belongs_to :generic_object
        t.string :label
      end

      create_table :creators do |t|
        t.belongs_to :generic_object
        t.string :label
      end

      create_table :contributors do |t|
        t.belongs_to :generic_object
        t.string :label
      end

      create_table :inst_image_files do |t|
        t.belongs_to :inst

        t.string :parent_pid
        t.string :path
        t.string :directory
        t.string :sha256
        t.string :mime_type

        t.boolean :low_res, :null => false, :default => false
        t.boolean :fedora_imported, :null => false, :default => false

        t.integer :views, :null => false, :default => 0

        t.timestamps null: false
      end

      create_table :base_files do |t|
        t.belongs_to :generic_object
        t.string :type

        t.string :parent_pid, limit: 64
        t.string :path
        t.string :directory
        t.string :sha256
        t.string :mime_type
        t.string :original_filename
        t.string :original_extension, limit: 10
        t.text :original_ocr, limit: 1.megabytes
        t.text :ocr, limit: 1.megabytes
        t.text :fits
        t.boolean :low_res, :null => false, :default => false
        t.boolean :fedora_imported, :null => false, :default => false

        t.integer :views, :null => false, :default => 0
        t.integer :downloads, :null => false, :default => 0
        t.integer :order, :null => false, :default => 0

        t.timestamps null: false
      end
      # May need to remove this as what about large books where blank pages are re-used as placeholders...
      add_index :base_files, [:parent_pid, :sha256], unique: true

      create_table :base_derivatives do |t|
        t.belongs_to :base_file
        t.string :type

        t.string :filename
        t.string :directory
        t.string :path
        t.string :mime_type, :null => false, :default => 'image/jpeg'
        t.string :sha256
        t.string :parent_sha256
        t.string :parent_pid, limit: 64 # technically a parent sha256 value
        t.text :ocr, limit: 1.megabytes

        t.integer :views, :null => false, :default => 0
        t.integer :downloads, :null => false, :default => 0
        t.integer :order, :null => false, :default => 0

        t.timestamps null: false
      end

    end
  end
end
