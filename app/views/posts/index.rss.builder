#encoding: UTF-8

xml.instruct! :xml, :version => "1.0"
xml.rss :version => "2.0",  'xmlns:atom'=>"http://www.w3.org/2005/Atom" do
  xml.channel do
    xml.title "Digital Transgender Archive News"
    xml.description "Latest news and updates from the DTA."
    xml.link "https://www.digitaltransgenderarchive.net/news"
    xml.language "en"
    xml.tag! 'atom:link', :rel => 'self', :type => 'application/rss+xml', :href => 'https://www.digitaltransgenderarchive.net/news.rss'

    for article in @posts
      xml.item do
        if article.title
          xml.title article.title
        else
          xml.title ""
        end
        #xml.author ""
        xml.pubDate article.created.to_s(:rfc822)
        xml.link "https://www.digitaltransgenderarchive.net/news/#{article.friendly_id}"
        xml.guid "https://www.digitaltransgenderarchive.net/news/#{article.friendly_id}"

        text = article.content
        text.gsub!('/uploads/ckeditor','https://www.digitaltransgenderarchive.net/uploads/ckeditor')
        xml.description "<p>" + text + "</p>"
      end
    end
  end
end
