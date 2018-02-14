class ModifyBlazer < ActiveRecord::Migration[5.2]
  def change
    unless ActiveRecord::Base.connection.column_exists?(:blazer_queries, :classification)
    change_table :blazer_queries do |t|
      t.string :classification, default: 'default', null: false
      t.boolean  :striped_style, default: true, null: false
      t.string :border_style, default: 'Full', null: false
      t.boolean :buttons_active, default: true, null: false
      t.boolean :search_active, default: true, null: false
      t.string :paging_style, default: 'Default', null: false
      t.boolean :compact_style, default: false, null: false
      t.integer   :page_size_default, default: 10, null: false
      t.integer   :scroll_size_default, default: 400, null: false
    end
    end

    unless ActiveRecord::Base.connection.column_exists?(:blazer_queries, :technical_notes)
      change_table :blazer_queries do |t|
        t.text :technical_notes
      end
    end

    unless ActiveRecord::Base.connection.table_exists?(:blazer_lists)
      create_table :blazer_lists do |t|
        t.references :creator
        t.string :identifier, unique: true
        t.string :name
        t.text :description
        t.timestamps null: false
      end

      create_table :blazer_list_items do |t|
        t.references :list
        t.text :name
        t.string :item
        t.timestamp :created_at
      end

    end
  end
end
