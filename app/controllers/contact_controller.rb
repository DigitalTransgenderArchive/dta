class ContactController < ApplicationController
  include DtaStaticBuilder

  before_action :get_latest_content

  before_action :set_nav_heading

  def index
    @errors=[]

    if request.post?
      if validate_email

        Notifier.feedback(params).deliver_now
        if Settings.mailchimp_key.present? and params[:email].present? and params[:name].present? and params[:newsletter].present? and params[:newsletter] == 'yes'
          begin
            gibbon = Gibbon::Request.new(api_key: Settings.mailchimp_key)
            gibbon.lists(Settings.mailchimp_id).members(Digest::MD5.hexdigest(params[:email])).upsert(body:
                                                                                                          {email_address: params[:email],
                                                                                                           status: "subscribed",
                                                                                                           merge_fields:
                                                                                                               {FNAME: params[:name].split(' ')[0],
                                                                                                                LNAME: params[:name].split(' ')[1..-1].join(' ')}})

          rescue Gibbon::MailChimpError => e
            puts "Gibson, we have a mailchimp problem: #{e.message} - #{e.raw_body}"
          end
        end
        redirect_to feedback_complete_path
      end
    end
  end


  def set_nav_heading
    @nav_section = 'Contact'
    @nav_items = []

    @nav_items << (ActionController::Base.helpers.link_to "Contact Us", contact_path, {class: 'active'})
  end

  def feedback_complete
    @nav_section = 'Contact'
    @nav_items = []
    @errors=[]

    @nav_items << (ActionController::Base.helpers.link_to "Contact Us", contact_path, {class: 'active'})
  end

  # validates the incoming params
  # returns either an empty array or an array with error messages
  def validate_email
    unless params[:name] =~ /\w+/
      @errors << t('blacklight.feedback.valid_name')
    end
    unless params[:email] =~ /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
      @errors << t('blacklight.feedback.valid_email')
    end
    unless params[:message] =~ /\w+/
      @errors << "Please enter an address"
    end
    unless verify_recaptcha(action: 'contact', minimum_score: 0.4, secret_key: Settings.recaptcha_secret_key_v3)
      if verify_recaptcha
        @show_captcha_v2 = false
      else
        @show_captcha_v2 = true
        @errors << 'Background recaptcha failed. Please try submitting your message again with the added checkbox captcha.'
      end

    end
    @errors.empty?
  end
end
