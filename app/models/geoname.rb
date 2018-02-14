class Geoname < ActiveRecord::Base
  serialize :alt_labels, Array
  serialize :hierarchy_full, Array
  serialize :hierarchy_display, Array
  serialize :geo_json_hash, Hash

  has_many :object_geonames
  has_many :generic_object, :through=>:object_genres

  def self.search(value, type)
    authority_check = Mei::Geonames.new(type)
    authority_result = authority_check.search(value) #URI escaping doesn't work for Baseball fields?
    if authority_result.present?
      return authority_result
    else
      return []
    end
  end
end
