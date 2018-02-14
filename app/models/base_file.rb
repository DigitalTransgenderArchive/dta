require 'fileutils'
require 'digest'

class BaseFile < ActiveRecord::Base
  has_paper_trail

  after_initialize :initialize_paths
  before_save :initialize_paths

  belongs_to :generic_object, optional: true
  has_many :base_derivatives

  def initialize_paths
    if self.needs_initialization?
      self.set_all
    end
  end

  def sha256=(value)
    self.initialize_paths
    super
  end

  def mime_type=(value)
    self.initialize_paths
    super
  end

  def needs_initialization?
    (self.mime_type.present?  && self.sha256.present?) && (self.path.blank? || self.directory.blank?)
  end

  def full_path
    File.join(Settings.filestore, self.path).to_s
  end

  def full_directory
    File.join(Settings.filestore, self.directory).to_s
  end

  def self.calculate_directory(sha256)
    dir1 = sha256[0..1]
    dir2 = sha256[2..3]
    return File.join(dir1, dir2, sha256).to_s
  end

  def self.calculate_path(directory, filename, mime_type)
    extension = BaseFile.calculate_extension mime_type
    File.join(directory, "#{filename}#{extension}").to_s
  end

  def set_all
    self.set_directory
    self.set_path
  end

  def set_directory
    if self.sha256_changed? || self.mime_type_changed? || self.needs_initialization?
      self.directory = BaseFile.calculate_directory(self.sha256)
    end
  end

  def set_path
    if self.directory.present?
      if self.sha256_changed? || self.mime_type_changed? || self.directory_changed? || self.needs_initialization?
        #self.path = BaseFile.calculate_path(self.directory, self.sha256, self.mime_type)
        self.path = BaseFile.calculate_path(self.directory, self.sha256, self.mime_type)
      end
    end
  end

  def self.calculate_sha256(content)
    Digest::SHA256.hexdigest content
  end

  def put(content)
    unless File.exists? full_path
      FileUtils.mkpath self.full_directory
      File.open(self.full_path, 'wb' ) do |output|
        output.write content
      end
    end
  end

  def self.calculate_extension(mime_type)
    case mime_type
      when 'image/jpeg'
        return '.jpeg'
      when 'image/png'
        return '.png'
      when 'image/tiff'
        return '.tiff'
      when 'image/gif'
        return '.gif'
      when 'application/pdf'
        return '.pdf'
      when 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
        return '.docx'
      else
        ".#{MIME::Types[mime_type].first.preferred_extension}"
    end
  end
end
