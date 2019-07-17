class ProcessTweetsWorker
  include Sidekiq::Worker
  sidekiq_options unique: :until_and_while_executing

  def perform
    # Get Tweets
    @api_tweets = Settings.twitter_client.user_timeline('digitaltransarc', count: 17, tweet_mode: "extended")

    @tweets = []
    @api_tweets.each do |tweet|
      unless  tweet.to_hash[:full_text].to_s.starts_with?("RT ") || tweet.to_hash[:full_text].to_s.length < 100 || tweet.to_hash[:in_reply_to_status_id].present? || tweet.to_hash[:retweeted].present?
        t = {}
        t[:url] = tweet.uri.to_s
        t[:raw_content] = tweet.to_hash[:full_text].to_s.dup

        #content =  Rinku.auto_link(tweet.full_text, :all, 'target="_blank"')
        content = t[:raw_content]

        tweet.hashtags.each do |tag|
          content.gsub!("##{tag.text.to_s}", "<a href='https://twitter.com/hashtag/#{tag.text.to_s}' target='_blank'>##{tag.text.to_s}</a>")
        end

        tweet.uris.each do |uri|
          if uri.expanded_url.to_s.starts_with?('https://twitter.com/')
            content.gsub!("#{uri.url.to_s}", "<a href='#{uri.expanded_url.to_s}' target='_blank'>#{uri.display_url.to_s}</a>")
          else
            content.gsub!("#{uri.url.to_s}", "<a href='#{uri.expanded_url.to_s}' target='_blank'>#{uri.expanded_url.to_s}</a>")
          end
        end
        tweet.media.each do |media|
          content.gsub!("#{media.url.to_s}", "<br /><img src='#{media.media_url}' class='tweet_img' />")
        end
        tweet.user_mentions.each do |user|
          content.gsub!("@#{user.screen_name.to_s}", "<a href='https://twitter.com/#{user.screen_name.to_s}' target='_blank'>@#{user.screen_name.to_s}</a>")
        end
        content.gsub!("\n", "\n<br />")

        t[:content] = content
        @tweets << t
      end
    end

    @tweets = @tweets[0..2]

    ActiveRecord::Base.transaction do
      if @tweets.present?
        NewsTweet.delete_all
        @tweets.each do |t|
          nt = NewsTweet.new
          nt.raw_content = t[:raw_content]
          nt.content = t[:content]
          nt.tweet_url = t[:url]
          nt.save!
        end
      end
    end
  end
end
