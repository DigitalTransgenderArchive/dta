#class HomepageController < ApplicationController
class HomepageController < ApplicationController
  # Give HomepageController access to the CatalogController configuration
  include Blacklight::Configurable
  include Blacklight::SearchHelper

  #include DtaStaticBuilder

  #before_action :get_latest_content
  copy_blacklight_config_from(CatalogController)

  layout 'home'

  def index

  end
end
