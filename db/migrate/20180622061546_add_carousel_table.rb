class AddCarouselTable < ActiveRecord::Migration[5.2]
  # The largest text column available in all supported RDBMS is
  # 1024^3 - 1 bytes, roughly one gibibyte.  We specify a size
  # so that MySQL will use `longtext` instead of `text`.  Otherwise,
  # when serializing very large objects, `text` might not be big enough.
  TEXT_BYTES = 1_073_741_823

  def change
    unless ActiveRecord::Base.connection.table_exists?(:carousels)
      create_table :carousel do |t|
        t.string   :collection_pid, limit: 64
        t.string   :image_pid, limit: 64
        t.string   :title
        t.string   :iiif
        t.text     :description
      end

    end
  end
end
