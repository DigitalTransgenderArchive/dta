require 'fileutils'
require 'digest'

class BaseDerivative < ActiveRecord::Base
  include FileBehavior

  before_save :verify_content_set

  belongs_to :base_file

  # Content handles most of the pathing logic
  def content=(value)
    self.sha256 = Digest::SHA256.hexdigest value
    self.set_parent_pid
    self.attempt_initialize!

    unless File.exists? full_path
      FileUtils.mkpath self.full_directory
      File.open(self.full_path, 'wb' ) do |output|
        output.write content
      end
    end
  end

  def attempt_initialize!
    self.parent_sha256 = self.base_file.sha256 if self.base_file.present?

    if self.parent_pid.present? and self.mime_type.present? and self.parent_sha256.present?
      self.do_initialize
    else
      self.error!
    end
  end

  def set_parent_pid
    self.parent_pid = self.base_file.parent_pid if self.parent_pid.nil?
  end

  def set_path
    if self.directory.present?
      self.path = BaseFile.calculate_path(self.directory, "#{self.parent_sha256}_#{local_name}_#{self.order}", self.mime_type)
    else
      raise 'Somehow have a file without a directory'
    end
  end

  def local_name
    raise "You should have this set in things that extend this class."
  end



end
