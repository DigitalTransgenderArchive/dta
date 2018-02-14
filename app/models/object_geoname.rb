class ObjectGeoname < ActiveRecord::Base
  belongs_to :generic_object
  belongs_to :geoname

end
