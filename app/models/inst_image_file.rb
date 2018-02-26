class InstImageFile < ActiveRecord::Base
  include FileBehavior

  # FIXME
  #before_save :verify_content_set

  belongs_to :inst

  def set_parent_pid
    self.parent_pid = self.inst.pid if self.parent_pid.nil?
  end

end
