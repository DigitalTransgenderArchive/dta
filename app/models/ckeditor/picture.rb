#class Ckeditor::Picture < Ckeditor::Asset
#  mount_uploader :data, CkeditorPictureUploader, :mount_on => :data_file_name

#  def url_content
#    url(:content)
#  end
#end

class Ckeditor::Picture < Ckeditor::Asset
  has_attached_file :data,
                    url: '/ckeditor_assets/pictures/:id/:style_:basename.:extension',
                    path: ':rails_root/public/ckeditor_assets/pictures/:id/:style_:basename.:extension',
                    styles: { content: '800>', thumb: '118x100#' }

  validates_attachment_presence :data
  validates_attachment_size :data, less_than: 100.megabytes
  validates_attachment_content_type :data, content_type: /\Aimage/

  def url_content
    url(:content)
  end
end