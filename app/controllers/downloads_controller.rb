class DownloadsController < ApplicationController

  def show
    if base_file.nil?
      raise 'File was nil'
    else
      if params["file"].present? and params["file"] == 'thumbnail' and thumbnail.present?
        file_name = "#{base_object.title.gsub(/[,;]/, '')}.#{thumbnail.path.split('.').last}"
        mime_type = thumbnail.mime_type
      else
        file_name = "#{base_object.title.gsub(/[,;]/, '')}.#{base_file.path.split('.').last}"
        mime_type = base_file.mime_type
      end

    end

    send_data get_content, type: mime_type, disposition: 'inline', filename: "#{file_name}"
  end

  def base_object
    @object ||= GenericObject.find_by(pid: params[:id])
  end

  def base_file
    @file ||= base_object.base_files[0]
  end

  def thumbnail
    @thumbnail ||= base_file.thumbnail_derivatives[0]
  end

  def get_content
    return '' if base_file.nil?

    if params["file"].present? and params["file"] == 'thumbnail'
      if thumbnail.nil?
        return base_file.content
      else
        return thumbnail.content
      end
    else
      return base_file.content
    end
  end

  def authorize!
    return true
  end

=begin
  def send_content
    if file.mime_type == "application/pdf"
      self.status = 200
      response.headers['Content-Length'] = file.size.to_s
      response.headers['Content-Disposition'] = "inline;filename=#{asset.label.gsub(/[,;]/, '')}.pdf"
      render body: file.content, content_type: "application/pdf"
    else
      super
    end

  end
=end

end
