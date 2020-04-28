#class Ckeditor::Asset < ActiveRecord::Base
#  include Ckeditor::Orm::ActiveRecord::AssetBase

#  delegate :url, :current_path, :content_type, :to => :data

#  validates_presence_of :data
#end
class Ckeditor::Asset < ActiveRecord::Base
  include Ckeditor::Orm::ActiveRecord::AssetBase
  include Ckeditor::Backend::Paperclip
end