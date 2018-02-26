class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  #layout 'blacklight'
  layout 'dta_layout'

  before_action :set_paper_trail_whodunnit

  def add_catalog_folder
    lookup_context.prefixes << "catalog"
  end

  def verify_superuser
    if !current_user.present? && !current_user.superuser?
      redirect_to root_path
    end
  end

  def verify_admin
    if !current_user.present? || (!current_user.admin? && !current_user.superuser?)
      redirect_to root_path
    end
  end

  def verify_contributor
    if !current_user.present? || (!current_user.admin? && !current_user.superuser? && !current_user.contributor?)
      redirect_to root_path
    end
  end

  def verify_homosaurus
    if !current_user.present? || (!current_user.admin? && !current_user.superuser? && !current_user.homosaurus?)
      redirect_to root_path
    end
  end

end
