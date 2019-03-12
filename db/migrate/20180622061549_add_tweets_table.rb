class AddTweetsTable < ActiveRecord::Migration[5.2]
  # The largest text column available in all supported RDBMS is
  # 1024^3 - 1 bytes, roughly one gibibyte.  We specify a size
  # so that MySQL will use `longtext` instead of `text`.  Otherwise,
  # when serializing very large objects, `text` might not be big enough.
  TEXT_BYTES = 1_073_741_823

  def change
    unless ActiveRecord::Base.connection.table_exists?(:news_tweets)
      # , :options => 'COLLATE=utf8mb4_unicode_ci'
      create_table :news_tweets do |t|
        t.string   :tweet_url, limit: 191
        t.binary     :raw_content, limit: 1000
        t.binary     :content, limit: 1500
        t.string   :quoted_url, limit: 191
        t.binary     :raw_quoted, limit: 1000
        t.binary     :quoted, limit: 1500
        t.timestamps null: false
      end

    end
  end
end
