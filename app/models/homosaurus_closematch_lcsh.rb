class HomosaurusClosematchLcsh < ActiveRecord::Base
  belongs_to :homosaurus
  belongs_to :lcsh_subject

  self.table_name = "homosaurus_closematch_lcsh"

end