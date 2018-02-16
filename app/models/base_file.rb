require 'fileutils'
require 'digest'

class BaseFile < ActiveRecord::Base
  include FileBehavior

  before_save :verify_content_set

  belongs_to :generic_object

  has_many :base_derivatives
  has_many :thumbnail_derivatives

  def set_parent_pid
    self.parent_pid = self.generic_object.pid if self.parent_pid.nil?
  end

end
