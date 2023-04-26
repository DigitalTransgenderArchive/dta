require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Dta
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    #config.autoload_paths += %W(#{config.root}/lib)
    config.eager_load_paths << Rails.root.join('lib')

    config.encoding = "utf-8"

    config.active_job.queue_adapter = :sidekiq

    config.action_mailer.delivery_method = :sendmail
    config.action_mailer.default_url_options = { :host => 'www.digitaltransgenderarchive.net' }

      #Needed for newer rails, see: https://stackoverflow.com/questions/71332602/upgrading-to-ruby-3-1-causes-psychdisallowedclass-exception-when-using-yaml-lo
      config.active_record.use_yaml_unsafe_load = true

    # See: https://github.com/galetahub/ckeditor/issues/919
    config.assets.resolve_assets_in_css_urls = false

    #config.assets.paths << Rails.root.join('app', 'assets', 'fonts')

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
  end
end
