class ObjectResourceType < ActiveRecord::Base
  belongs_to :generic_object
  belongs_to :resource_type

end
