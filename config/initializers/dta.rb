Dta::Application.config do |config|
  config.cc_licenses = {
      'Contact host institution for more information' => 'Contact host institution for more information',
      'No known restrictions on use' => 'No known restrictions on use',
      'All rights reserved' => 'All rights reserved'
  }

  config.flagged_list = {
      "No explicit content" => "No explicit content",
      "Explicit content in thumbnail" => "Explicit content in thumbnail",
      "Explicit content, but not in thumbnail" => "Explicit content, but not in thumbnail"
  }

  config.geonames_username = 'boston_library'

  config.cc_licenses_reverse = Hash[*config.cc_licenses.to_a.flatten.reverse]

  config.spatial_dropdown = [
      ['Cities', 'P'],
      ['Building', 'S'],
      ['State/Country/Region', 'A'],
      ['Geographic Territory', 'T'],
      ['Continent/Area', 'L']
  ]

  config.analytics = false

  # Specify a Google Analytics tracking ID to gather usage statistics
  # config.google_analytics_id = 'UA-99999999-1'

  config.fits_path = ENV["FITS_PATH"]

  Date::DATE_FORMATS[:standard] = "%m/%d/%Y"
end

# Noid config
require 'noid-rails'
#ActiveFedora::Base.translate_uri_to_id = Noid::Rails.config.translate_uri_to_id
#ActiveFedora::Base.translate_id_to_uri = Noid::Rails.config.translate_id_to_uri
#baseparts = 2 + [(Noid::Rails.config.template.gsub(/\.[rsz]/, '').length.to_f / 2).ceil, 4].min
ActiveFedora::Base.translate_uri_to_id = lambda do |uri|
  baseparts = 2 + [(::Noid::Rails.config.template.gsub(/\.[rsz]/, '').length.to_f / 2).ceil, 4].min
  uri.to_s.sub("#{ActiveFedora.fedora.host}#{ActiveFedora.fedora.base_path}", '').split('/', baseparts).last
end
ActiveFedora::Base.translate_id_to_uri = lambda do |id|
  "#{ActiveFedora.fedora.host}#{ActiveFedora.fedora.base_path}/#{::Noid::Rails.treeify(id)}"
end
