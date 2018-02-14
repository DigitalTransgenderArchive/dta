class Rights < ActiveRecord::Base
  has_many :object_rights
  has_many :generic_object, :through=>:object_rights

end
