module DtaSearchHelper
  include ::BlacklightHelper

  # You can configure blacklight to use this as the thumbnail
  # example:
  #   config.index.thumbnail_method = :sufia_thumbnail_tag
  def dta_thumbnail_tag(document, options)
    # Hash check is odd..
    if document['model_ssi'] == 'Collection' || document.collection?
      if document["thumbnail_ident_ss"].present?
        path = download_path document["thumbnail_ident_ss"], file: 'thumbnail'
        options[:alt] = ""
        return image_tag path, options
      elsif document["hasCollectionMember_ssim"].present?
        document["hasCollectionMember_ssim"].each do |member|
          visibility_check = DSolr.find({q: "id:#{member}", rows: '1', fl: 'id,visibility_ssi,flagged_tesim,mime_type_tesim'} ).first
          if visibility_check.present? and visibility_check['visibility_ssi'] == 'public' and visibility_check['flagged_tesim'] != ['Explicit content in thumbnail'] and visibility_check['mime_type_tesim'].present? and visibility_check['mime_type_tesim'].any? {|v| v.include?('image') || v.include?('pdf') }
            path = download_path member, file: 'thumbnail'
            options[:alt] = ""
            return image_tag path, options
          end
        end
      end
      options[:alt] = ""
      return image_tag "shared/collection-icon.svg", options
    elsif document.institution?
      if document['has_image_ssi'] == 'true'
        path = download_path document, file: 'content', institution: 'true'
        options[:alt] = ""
        return image_tag path, options
      end
      options[:alt] = ""
      return image_tag "shared/institution_icon.png", options
    elsif document.object?
          path =
              if document['flagged_tesim'] == ['Explicit content in thumbnail']
                "shared/dta_default_icon.jpg"
              elsif document.has_thumbnail?
                download_path document, file: 'thumbnail'
              elsif document.audio?
                #"audio.png"
                "shared/dta_audio_icon.jpg"
              else
                "shared/dta_default_icon.jpg"
              end
          options[:alt] = ""
          return image_tag path, options
    end


    return image_tag "default.png"
  end
end
