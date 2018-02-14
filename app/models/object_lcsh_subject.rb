class ObjectLcshSubject < ActiveRecord::Base
  belongs_to :generic_object
  belongs_to :lcsh_subject

end
