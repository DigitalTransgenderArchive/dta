module CatalogHelper
  include Blacklight::CatalogHelperBehavior
# render the date in the catalog#index list view
  def index_date_value options={}
    document = options[:document]
    if document[:date_created_tesim]
      document[:date_created_tesim].first
    elsif document[:date_issued_tesim]
      document[:date_issued_tesim].first
    else
      nil
    end
  end

  def institution_icon_path
    'shared/institution_icon.png'
  end

# determine the 'truncate' length based on catalog#index view type
  def index_title_length
    case params[:view]
      when 'list'
        170
      when 'masonry'
        89
      else
        130
    end
  end


end