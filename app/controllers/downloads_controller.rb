class DownloadsController < ApplicationController
  include Sufia::DownloadsControllerBehavior

  def authorize_download!
    if params["file"].present? and params["file"] == 'thumbnail'
      return true
    else
      #authorize! :download, file
      return true
    end
  end

  #FIXME: This is cached in sufia... means that users can't see files changed sometimes...
  def file
    #load_file
    @file ||= load_file
  end

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

  # Override this if you'd like a different filename
  # @return [String] the filename
  def file_name
    potential_name = params[:filename] || file.original_name || (asset.respond_to?(:label) && asset.label) || file.id
    potential_name = potential_name.gsub(/[,;]/, '')
    potential_extension = ''
    if file.mime_type == 'image/png'
      potential_extension = '.png'
    elsif file.mime_type == 'image/tiff'
      potential_extension = '.png'
    elsif file.mime_type == 'image/jpeg' || file.mime_type == 'image/jpg'
      potential_extension = '.jpg'
    end
    return potential_name
    #return potential_name + potential_extension
  end

end