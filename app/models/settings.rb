class Settings


  def self.twitter_client
    @client ||= Twitter::REST::Client.new do |config|
      config.consumer_key        = Settings.dta_config["twitter_consumer_key"]
      config.consumer_secret     = Settings.dta_config["twitter_consumer_secret"]
      config.access_token        = Settings.dta_config["twitter_access_token"]
      config.access_token_secret = Settings.dta_config["twitter_access_token_secret"]
    end
    @client
  end

  def self.filestore
    @filestore_path ||= Settings.dta_config["filestore_path"]
    raise "filestore_path in dta.yml could not be detected" if @filestore_path.blank?
    @filestore_path
  end

  def self.google_analytics_id
    @google_analytics_id ||= Settings.dta_config["google_analytics_id"]
  end

  def self.mailchimp_key
    @mailchimp_key ||= Settings.dta_config["mailchimp_key"]
  end

  def self.mailchimp_id
    @mailchimp_id ||= Settings.dta_config["mailchimp_id"]
  end

  def self.recaptcha_site_key
    @recaptcha_site_key ||= Settings.dta_config["recaptcha_site_key"]
  end

  def self.recaptcha_secret_key
    @recaptcha_secret_key ||= Settings.dta_config["recaptcha_secret_key"]
  end

  def self.recaptcha_site_key_v3
    @recaptcha_site_key_v3 ||= Settings.dta_config["recaptcha_site_key_v3"]
  end

  def self.recaptcha_secret_key_v3
    @recaptcha_secret_key_v3 ||= Settings.dta_config["recaptcha_secret_key_v3"]
  end

  # FIXME!
  def self.fits_path
    @fits_path ||= Settings.dta_config["fits_path"]
    raise "fits path in dta.yml could not be detected" if @fits_path.blank?
    @fits_path
  end

  def self.libreoffice_path
    @libreoffice_path ||= Settings.dta_config["libreoffice_path"]
    raise "libr office path in dta.yml could not be detected" if @libreoffice_path.blank?
    @libreoffice_path
  end

  def self.solr_url
    @solr_url ||= Settings.solr_config["url"]
    raise "url in blacklight.yml could not be detected" if @solr_url.blank?
    @solr_url
  end

  def self.solr_config
    @solr_config ||= YAML.load_file(File.join(Rails.root, "config", "solr.yml"))[Rails.env.to_s]
    raise "blacklight yml file seems to not exist" if @solr_config.nil?
    @solr_config
  end

  def self.dta_config
    @dta_config ||= YAML.load_file(File.join(Rails.root, "config", "dta.yml"))[Rails.env.to_s]
    raise "Dta configuration yml file seems to not exist" if @dta_config.nil?
    @dta_config
  end

  def self.app_root
    return @app_root if @app_root
    @app_root = Rails.root if defined?(Rails) and defined?(Rails.root)
    @app_root ||= APP_ROOT if defined?(APP_ROOT)
    @app_root ||= '.'
  end

  def self.env
    return @env if @env
    #The following commented line always returns "test" in a rails c production console. Unsure of how to fix this yet...
    #@env = ENV["RAILS_ENV"] = "test" if ENV
    @env ||= Rails.env if defined?(Rails) and defined?(Rails.root)
    @env ||= 'development'
  end
end
