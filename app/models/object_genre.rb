class ObjectGenre < ActiveRecord::Base
  belongs_to :generic_object
  belongs_to :genre

end
