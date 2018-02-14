require 'fileutils'
require 'digest'

class BaseDerivative < ActiveRecord::Base
  after_initialize :initialize_paths
  before_save :initialize_paths

  belongs_to :base_file

  def local_name
    raise "You should have this set in things that extend this class."
  end

  def initialize_paths
    if self.needs_initialization?
      self.set_all
    end
  end

  def base_file=(value)
    self.initialize_paths
    super
  end

  def base_file_id=(value)
    self.initialize_paths
    super
  end

  def mime_type=(value)
    self.initialize_paths
    super
  end

  def needs_initialization?
    (self.mime_type.present? && self.base_file.present?) && (self.path.blank? || self.directory.blank? || self.filename.blank?)
  end

  def full_path
    File.join(Settings.filestore, self.path).to_s
  end

  def full_directory
    File.join(Settings.filestore, self.directory).to_s
  end

  def set_all
    self.filename = "#{self.local_name}"
    self.set_directory
    self.set_path
  end

  def set_directory
    if self.base_file_id_changed? || self.needs_initialization?
      self.directory = self.base_file.directory
    end
  end

  def set_path
    if self.directory.present?
      if self.base_file_id_changed? || self.directory_changed? || self.needs_initialization?
        self.path = BaseFile.calculate_path(self.directory, self.filename, self.mime_type)
      end
    end
  end

  def put(content)
    self.sha256 = BaseFile.calculate_sha256 content
    unless File.exists? full_path
      FileUtils.mkpath self.full_directory
      File.open(self.full_path, 'wb' ) do |output|
        output.write content
      end
    end
  end

end
