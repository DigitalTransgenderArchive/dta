class HomosaurusUriSubject < ActiveRecord::Base
  serialize :language_labels, Array
  serialize :alt_labels, Array
  serialize :broader, Array
  serialize :narrower, Array
  serialize :related, Array

  has_many :object_homosaurus_uri_subject
  has_many :generic_object, :through=>:object_homosaurus_uri_subject

end
