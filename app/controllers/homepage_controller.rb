#class HomepageController < ApplicationController
class HomepageController < ApplicationController
  # Give HomepageController access to the CatalogController configuration
  include Blacklight::Configurable
  include Blacklight::SearchHelper

  include DtaStaticBuilder

  before_action :get_latest_content
  copy_blacklight_config_from(CatalogController)

  layout 'home'
#iiif: "https://repository.digitaltransgenderarchive.net:8182/iiif/2/#{GenericObject.find_by(pid: 'fx719m50n').iiif_id}/full/,760/0/default.jpg",
#iiif: "https://repository.digitaltransgenderarchive.net:8182/iiif/2/#{GenericObject.find_by(pid: 'fx719m50n').iiif_id}/0,0,3840,2560/max/0/default.jpg",

  def index
    @carousel = []
    Carousel.all.each do |c|
      @carousel << {collection_pid: c.collection_pid,
                    image_pid: c.image_pid,
                    title: c.title,
                    iiif: c.iiif,
                    description: c.description}

    end

    @tweets = NewsTweet.all

  end
end
