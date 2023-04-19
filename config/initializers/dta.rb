Rails.application.config.cc_licenses_uri = {
    'No known copyright' => 'https://rightsstatements.org/page/NKC/1.0/?language=en',
    'Copyright undetermined' => 'https://rightsstatements.org/page/UND/1.0/?language=en',
    'In copyright' => 'https://rightsstatements.org/page/InC/1.0/?language=en',
    'Copyright not evaluated' => 'https://rightsstatements.org/page/CNE/1.0/?language=en'
}

Dta::Application.config do |config|
  config.cc_licenses = {
      'Contact host institution for more information' => 'Contact host institution for more information',
      'No known restrictions on use' => 'No known restrictions on use',
      'All rights reserved' => 'All rights reserved'
  }

  #config.cc_licenses_uri = {
  #    'Copyright undetermined' => 'https://rightsstatements.org/page/NKC/1.0/?language=en',
  #    'No known copyright' => 'https://rightsstatements.org/page/UND/1.0/?language=en',
  #    'In copyright' => 'https://rightsstatements.org/page/InC/1.0/?language=en',
  #    'Copyright not evaluated' => 'https://rightsstatements.org/page/CNE/1.0/?language=en'
  #}

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
