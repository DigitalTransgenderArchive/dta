class DownloadsController < ApplicationController

  def show
    if base_file.nil?
      raise 'File was nil'
    elsif base_file.class.to_s != "InstImageFile" && base_file.generic_object.visibility != 'public' && !current_or_guest_user.contributor?
      # not public - redirect to root
      redirect_to root_path
    else
      if params["file"].present? and params["file"] == 'thumbnail' and thumbnail.present?
        file_name = "#{base_object.title.gsub(/[,;]/, '')}.#{thumbnail.path.split('.').last}"
        mime_type = thumbnail.mime_type
      else

        mime_type = base_file.mime_type
        if params["file"].present? and (params["file"] == 'preview' or params["file"] == 'carousel')
          mime_type = thumbnail.mime_type
        end
        if params.blank? || params[:institution].blank?
          file_name = "#{base_object.title.gsub(/[,;]/, '')}.#{base_file.path.split('.').last}"
          # ahoy.track_visit
          #  ahoy.track "Object Download", {title: @object.title}, {collection_pid: @object.coll.pid, institution_pid: @object.inst.pid, pid: params[:id], model: "GenericObject", search_term: session[:search_term]}
          #base_object.downloads = base_object.downloads + 1
          #base_object.save!
        else
          file_name = "#{base_object.name.gsub(/[,;]/, '')}.#{base_file.path.split('.').last}"
        end
      end
      send_data get_content, type: mime_type, disposition: 'inline', filename: "#{file_name}"
    end

  end

  def base_object
    if params[:institution].present?
      @object ||= Inst.find_by(pid: params[:id])
    else
      @object ||= GenericObject.find_by(pid: params[:id])
    end

  end

  def base_file
    if params[:institution].present?
      @file ||= base_object.inst_image_files[0]
    else
      if params[:index].present?
        @file ||= base_object.base_files[params[:index].to_i]
      else
        @file ||= base_object.base_files[0]
      end
    end
  end

  def thumbnail
    if params[:institution].present?
      @file ||= base_file
    else
      @thumbnail ||= base_file.thumbnail_derivatives[0]
    end
  end

  def preview
    if params[:institution].present?
      @preview ||= base_file
    else
      @preview ||= base_file.preview_derivatives[0]
    end
  end

  def carousel
    if params[:institution].present?
      @carousel ||= base_file
    else
      @carousel ||= base_file.carousel_derivatives[0]
    end
  end

  def get_content
    return '' if base_file.nil?
    if params["file"].present? and params["file"] == 'carousel'
      unless carousel.nil?
        return carousel.content
      end
    end

    if params["file"].present? and params["file"] == 'preview'
      unless preview.nil?
        return preview.content
      end
    end

    if params["file"].present? and (params["file"] == 'thumbnail' || params["file"] == 'preview')
      unless thumbnail.nil?
        return thumbnail.content
      end
    end


    return base_file.content
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
