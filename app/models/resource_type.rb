class ResourceType < ActiveRecord::Base
  has_many :object_resource_types
  has_many :generic_object, :through=>:object_resource_types
end
