class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  #layout 'blacklight'
  layout 'dta_layout'

  before_action :set_paper_trail_whodunnit

end
