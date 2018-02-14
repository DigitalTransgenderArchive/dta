module DtaSearchHelper
  include ::BlacklightHelper

  # You can configure blacklight to use this as the thumbnail
  # example:
  #   config.index.thumbnail_method = :sufia_thumbnail_tag
  def dta_thumbnail_tag(document, options)

    return image_tag "default.png"
    # collection
    if document.collection?
      #FIXME: This can be done more efficiently...
      if document["thumbnail_ident_ss"].present?
        path = sufia.download_path document["thumbnail_ident_ss"], file: 'thumbnail'
        options[:alt] = ""
        return image_tag path, options
      elsif document["hasCollectionMember_ssim"].present?
        document["hasCollectionMember_ssim"].each do |member|
          visibility_check = GenericFile.find_with_conditions("id:#{member}", rows: '1', fl: 'id,is_public_ssi,flagged_tesim,mime_type_tesim' ).first
          if visibility_check.present? and visibility_check['is_public_ssi'] == 'true' and visibility_check['flagged_tesim'] != ['Explicit content in thumbnail'] and visibility_check['mime_type_tesim'].present? and visibility_check['mime_type_tesim'].any? {|v| v.include?('image') || v.include?('pdf') }
            path = download_path member, file: 'thumbnail'
            options[:alt] = ""
            return image_tag path, options
          end
        end

      end

      #No image found
      #content_tag(:span, "", class: "glyphicon glyphicon-th collection-icon-search")
      options[:alt] = ""
      return image_tag "site_images/collection-icon.svg", options

      #content_tag(:span, "", class: "glyphicon glyphicon-th collection-icon-search")

      # file
      #FIXME: DO THIS BETTER
    elsif document["active_fedora_model_ssi"] == "Institution"
      if document['has_image_ssi'] == 'true'
        path = download_path document, file: 'content'
        options[:alt] = ""
        return image_tag path, options
      end
      options[:alt] = ""
      image_tag "shared/institution_icon.png", options
    else
      path =
          if document['flagged_tesim'] == ['Explicit content in thumbnail']
            "shared/dta_default_icon.jpg"
          elsif document.image? || document.pdf? || document.video? || document.office_document?
            download_path document, file: 'thumbnail'
          elsif document.audio? || (document['resource_type_tesim'].present? and document['resource_type_tesim'].include?('Audio')) || (document['genre_tesim'].present? and document['genre_tesim'].include?('Sound Recordings'))
            #"audio.png"
            "shared/dta_audio_icon.jpg"
          else
            "default.png"
          end
      options[:alt] = ""
      image_tag path, options
    end
  end
end
