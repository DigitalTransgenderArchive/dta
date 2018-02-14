class Genre < ActiveRecord::Base
  has_many :object_genres
  has_many :generic_object, :through=>:object_genres

end
