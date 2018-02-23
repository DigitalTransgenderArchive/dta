require 'fileutils'
require 'digest'

class BaseFile < ActiveRecord::Base
  has_paper_trail

  include FileBehavior

  #before_save :verify_content_set

  belongs_to :generic_object

  has_many :base_derivatives
  has_many :thumbnail_derivatives

  def set_parent_pid
    self.parent_pid = self.generic_object.pid if self.parent_pid.nil?
  end

  def start_derivative
    return self.thumbnail_derivatives.first if self.thumbnail_derivatives.present?
    derivative = ThumbnailDerivative.new
    derivative.base_file = self
    derivative
  end


  def pdf_ocr(passed_content)
    text_content = ''
    begin
      reader = PDF::Reader.new(StringIO.open(passed_content))

      text_content = []
      reader.pages.each do |page|
        begin
          text_content << page.text
        rescue NoMethodError
          # Ignored for now. Was "undefined method `/' for nil:NilClass"
        end
      end
      #cntrl is for control characters. Taken from: https://github.com/sunspot/sunspot/issues/570
      text_content = text_content.join(" ").gsub(/\n/, ' ').gsub(/\uFFFF/, ' ').gsub(/[[:cntrl:]]/,' ').squish
    rescue PDF::Reader::MalformedPDFError => ex
      #Ignore this...malformed PDF. Might be able to patch as posted in:
      #https://groups.google.com/forum/#!topic/pdf-reader/e_Ba-myn584
    rescue => ex
      # Line 104 of reader.pages.each do |page| can raise an error message of
      # NoMethodError: undefined method `flatten' for nil:NilClass
      # Likely a nil value of text in PDF...
      unless ex.message.include?('flatten')
        raise ex
      end
    end

    return text_content
  end

end
