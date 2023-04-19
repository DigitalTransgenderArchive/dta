# encoding: utf-8

# https://github.com/CollegeOfTheHolyCross/dta_sufia/tree/master/lib/dta_lib
require 'zip'
require "net/http"
require "uri"
require 'open-uri'
require 'nokogiri'

AUDIO_TYPES = ['mp3', 'wav', 'mp4']

class IngestBase
  def self.fetch(uri_str, retryLimit = 10)
    if Settings.dta_config["proxy_host"].present?
      doc = Nokogiri.HTML(open(uri_str, proxy: URI.parse("http://#{Settings.dta_config['proxy_host']}:#{Settings.dta_config['proxy_port']}")))

    else
      doc = Nokogiri.HTML(open(uri_str))
    end

    doc.content
  end

  def self.fetch_links(uri_str, retryLimit = 10)
    if Settings.dta_config["proxy_host"].present?
      doc = Nokogiri.HTML(open(uri_str, proxy: URI.parse("http://#{Settings.dta_config['proxy_host']}:#{Settings.dta_config['proxy_port']}")))

    else
      doc = Nokogiri.HTML(open(uri_str))
    end
    nodeset = doc.xpath('//a')

    nodeset.map {|element| element["href"]}.compact
  end

  def self.fetch_images(uri_str, retryLimit = 10)
    if Settings.dta_config["proxy_host"].present?
      doc = Nokogiri.HTML(open(uri_str, proxy: URI.parse("http://#{Settings.dta_config['proxy_host']}:#{Settings.dta_config['proxy_port']}")))

    else
      doc = Nokogiri.HTML(open(uri_str))
    end
    nodeset = doc.xpath('//img')

    nodeset.map {|element| element["src"]}.compact
  end

  def self.fetch_xml(uri_str)
    if Settings.dta_config["proxy_host"].present?
      doc = Nokogiri.XML(open(uri_str, proxy: URI.parse("http://#{Settings.dta_config['proxy_host']}:#{Settings.dta_config['proxy_port']}")))
    else
      doc = Nokogiri.XML(open(uri_str))
    end
    doc
  end

  def self.fetch_broken(uri_str, limit = 10)
    # You should choose better exception.
    raise ArgumentError, 'HTTP redirect too deep' if limit == 0

    url = URI.parse(uri_str)
    req = Net::HTTP::Get.new(url.path, { 'User-Agent' => 'Mozilla/5.0 (etc...)' })
    response = Net::HTTP.start(url.host, url.port, :use_ssl => url.scheme == 'https') { |http| http.request(req) }
    case response
    when Net::HTTPSuccess     then response
    when Net::HTTPRedirection then fetch(response['location'], limit - 1)
    else
      response.error!
    end
  end

  def self.get_redirect(uri_str)
    # You should choose better exception.
    url = URI.parse(uri_str)
    req = Net::HTTP::Get.new(url.path, { 'User-Agent' => 'Mozilla/5.0 (etc...)' })
    response = Net::HTTP.start(url.host, url.port, :use_ssl => url.scheme == 'https') { |http| http.request(req) }
    case response
    when Net::HTTPRedirection then return response['location']
    else
      response.error!
    end
  end

  def insert_date_created(date_text)
    original_date = date_text.clone

    date_text = '1985/1989' if date_text == 'between 1985 and 1989'
    date_text = '1980?/1989?' if date_text == '1980sca.' || date_text == 'ca. 1980s'
    date_text = '1980/1984' if date_text == '1980 / 1984'
    date_text = '1986~' if date_text == 'circa 1986'
    date_text = '1985~' if date_text == 'ca. 1985' || date_text == 'circa 1985'
    date_text = date_text.split(" ")[0] if date_text.include?(" (postmarked)")

    approximate = false
    if date_text.include?("approximately ")
      date_text.gsub!("approximately ", "")
    end

    # January 1990
    if date_text.match(/^#{Date::MONTHNAMES[1..-1].join('|')} \d{4}$/).present?
      date_text = date_text.split(' ')[1] + "-" + Date::MONTHNAMES.index(date_text.split(' ')[0]).to_s.rjust(2, "0")
    end

    # ca. 1974
    # circa 1974
    if date_text.match(/^ca\. \d\d\d\d$/).present? || date_text.match(/^circa \d\d\d\d$/).present?
      date_text = date_text.split(" ")[1] + "~"
    end

    if date_text.match(/^\d\d\d\d\-\d\d\d\d$/)
      date_text = date_text.strip.gsub('-','/')
    end

    date_text = date_text + "~" if approximate

    date = Date.edtf(date_text)

    if date.present?
      @generic_object.date_created += [date.edtf]
    elsif date_text.present?
      raise "Could not parse date for: " + original_date
    end
  end

  def self.insert_subject(subject_element, record_id)
    if subject_element.strip.downcase == 'group portraits'
      @generic_file.homosaurus_subject += ['http://id.loc.gov/authorities/subjects/sh85105182']
    elsif subject_element.strip.downcase == 'flowers (plants)'
      @generic_file.homosaurus_subject += ['http://id.loc.gov/authorities/subjects/sh85049332']
    elsif subject_element.strip.downcase == 'banjos'
      @generic_file.homosaurus_subject += ['http://id.loc.gov/authorities/subjects/sh85011545']
    elsif subject_element.strip.downcase == 'costumes'
      @generic_file.homosaurus_subject += ['http://id.loc.gov/authorities/subjects/sh85033238']
    elsif subject_element.strip.downcase == 'guitars'
      @generic_file.homosaurus_subject +=  ['http://id.loc.gov/authorities/subjects/sh85057803']
    elsif subject_element.strip.downcase == 'dressing rooms'
      @generic_file.homosaurus_subject +=  ['http://id.loc.gov/authorities/subjects/sh94005982']
    elsif subject_element.strip.downcase == 'violins'
      @generic_file.homosaurus_subject += ['http://id.loc.gov/authorities/subjects/sh85143544']
    elsif subject_element.strip.downcase == 'steps'
      # This is stairs
      @generic_file.homosaurus_subject += ['http://id.loc.gov/authorities/subjects/sh85127267']
    else

      solr_response = Homosaurus.find_with_conditions("dta_homosaurus_lcase_prefLabel_ssi:#{solr_clean(subject_element.strip.downcase)}", rows: '25', fl: 'identifier_ssi, prefLabel_ssim, altLabel_ssim, narrower_ssim, broader_ssim, related_ssim' ) unless subject_element.strip.include?('(')
      if solr_response.present? and solr_response.count == 1
        @generic_file.homosaurus_subject += ['http://homosaurus.org/terms/' + solr_response.first['identifier_ssi']]
      elsif  solr_response.present? and solr_response.count > 1
        raise "Solr count mismatch for " + record_id
      else
        authority_check = Mei::Loc.new('subjects')
        authority_result = authority_check.search(subject_element.strip) #URI escaping doesn't work for Baseball fields?
        if authority_result.present?
          authority_result = authority_result.select{|hash| hash['label'].downcase == subject_element.strip.downcase }
          if  authority_result.present?
            @generic_file.homosaurus_subject += [authority_result.first["uri_link"].gsub('info:lc', 'http://id.loc.gov')]
          else
            raise "No homosaurus or LCSH match for " + record_id + " for subject value: " + subject_element.strip
          end
        end
      end
    end
  end

  def self.process_image(obj, image_url, filename)
    if Settings.dta_config["proxy_host"].present?
      image = MiniMagick::Image.open(image_url, nil, {proxy: URI.parse("http://#{Settings.dta_config['proxy_host']}:#{Settings.dta_config['proxy_port']}")})
    else
      image = MiniMagick::Image.open(image_url)
    end

    image.format "jpg"
    image.resize "500x600"
    obj.add_file(image.to_blob, 'image/jpeg', filename)
  end


  def self.solr_clean(term)
    return term.gsub('\\', '\\\\').gsub(':', '\\:').gsub(' ', '\ ')
  end
end