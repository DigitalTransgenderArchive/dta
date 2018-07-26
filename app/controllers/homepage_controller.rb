#class HomepageController < ApplicationController
class HomepageController < ApplicationController
  # Give HomepageController access to the CatalogController configuration
  include Blacklight::Configurable
  include Blacklight::SearchHelper

  include DtaStaticBuilder

  before_action :get_latest_content
  copy_blacklight_config_from(CatalogController)

  layout 'home'

  def index
    @carousel = []
    @carousel << {collection_pid: "5999n337h",
                  image_pid: 'fx719m50n',
                  title: "Alison Laing's Photographs",
                  iiif: "https://repository.digitaltransgenderarchive.net:8182/iiif/2/#{GenericObject.find_by(pid: 'fx719m50n').iiif_id}/full/,760/0/default.jpg",
                  description: "These photographs, primarily taken by unknown photographers with a few taken by Mariette Pathy Allen, document Alison Laing speaking, performing, and interacting with others at various events such as Fantasia Fairs and IFGE Houston. They feature a variety of trans activists, including Dottie Laing, Dallas Denny, Ariadne Kane, JoAnn Roberts, and Virginia Prince. This collection also includes professional portraits of Alison and Dottie Laing."}
    @carousel << {collection_pid: "g158bh328",
                  image_pid: 'w9505051c',
                  title: "Phyllis Frye Collection",
                  iiif: "https://repository.digitaltransgenderarchive.net:8182/iiif/2/#{GenericObject.find_by(pid: 'w9505051c').iiif_id}/full/,760/0/default.jpg",
                  description: "Phyllis Randolph Frye is the first openly transgender judge in the United States. She is also a US Army veteran, a licensed engineer, an attorney, and a prominent trans activist. Photographs in this collection include 11 photographs and 1 certificate from the US Army, documents her life journey between 1962 and 2006. It reflects her life before transitioning as well as her important role in the movement for transgender rights."}
    @carousel << {collection_pid: "4m90dv65c",
                  image_pid: '44558d50p',
                  title: "Berg and Høeg Photographs",
                  iiif: "https://repository.digitaltransgenderarchive.net:8182/iiif/2/#{GenericObject.find_by(pid: '44558d50p').iiif_id}/full/,760/0/default.jpg",
                  description: "Marie Høeg (1866-1949) and Bolette Berg (1872-1944) were Norwegian photographers from Horton, Norway. Marie, the more outgoing of the two, was an active women's rights advocate who also enjoyed crossdressing in private. A private collection of photographs form the Berg and Høeg photography studio primarily shows Marie, with occasional appearances of Bolette, crossdressing in various fashions. These photographs show Marie's willingness to digress from and contradict social norms."}
  end
end
