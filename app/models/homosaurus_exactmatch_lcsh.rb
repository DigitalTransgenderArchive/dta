class HomosaurusExactmatchLcsh < ActiveRecord::Base
  belongs_to :homosaurus_subject
  belongs_to :lcsh_subject

  self.table_name = "homosaurus_exactmatch_lcsh"
end