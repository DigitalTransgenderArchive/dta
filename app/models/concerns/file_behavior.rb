module FileBehavior
  extend ActiveSupport::Concern

  # These are class methods
  class_methods do
    def calculate_sha256(content)
      Digest::SHA256.hexdigest content
    end

    def calculate_directory(parent_pid)
      Pid.tree(parent_pid)
    end

    def calculate_path(directory, filename, mime_type)
      extension = BaseFile.calculate_extension mime_type
      File.join(directory, "#{filename}#{extension}").to_s
    end

    def calculate_extension(mime_type)
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

  # These are instance methods
  def delete
    self.destroy
  end

  # Content handles most of the pathing logic
  def content=(value)
    raise 'No value was passed for the file...' if value.blank?
    self.sha256 = Digest::SHA256.hexdigest value # Can calculate twice...
    self.set_parent_pid
    self.attempt_initialize!

    unless File.exists? full_path
      FileUtils.mkpath self.full_directory
      File.open(self.full_path, 'wb' ) do |output|
        output.write value
      end
    end
  end

  def content
    ::File.open(File.join(Settings.filestore, self.path), 'rb') { |f| f.read }
  end

  def error!
    raise "Cannot set a base file as missing an object, a mime_type, or content.
           SHA256: #{self.sha256.to_s} , parent_id: #{self.parent_pid.to_s}, path: #{self.path.to_s}, directory: #{self.directory.to_s}"
  end

  def attempt_initialize!
    if self.parent_pid.present? and self.mime_type.present?
      self.do_initialize
    else
      self.error!
    end
  end

  def do_initialize
    self.set_directory
    self.set_path
  end

  def verify_content_set
    # Should check this at end: || !File.exists?(self.path)
    error! if self.parent_pid.blank? || self.sha256.blank? || self.path.blank? || self.directory.blank?
  end

  def full_path
    File.join(Settings.filestore, self.path).to_s
  end

  def full_directory
    File.join(Settings.filestore, self.directory).to_s
  end

  def set_directory
    self.directory = BaseFile.calculate_directory(self.parent_pid)
  end

  def set_path
    if self.directory.present?
        self.path = BaseFile.calculate_path(self.directory, self.sha256, self.mime_type)
    else
      raise 'Somehow have a file without a directory'
    end
  end

end
