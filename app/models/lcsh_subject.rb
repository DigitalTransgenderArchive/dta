class LcshSubject < ActiveRecord::Base
  serialize :alt_labels, Array
  serialize :broader, Array
  serialize :narrower, Array
  serialize :related, Array

  has_many :object_lcsh_subject
  has_many :generic_object, :through=>:object_lcsh_subject

end
