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

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
  end
end
