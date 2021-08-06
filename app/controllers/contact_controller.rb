class ContactController < ApplicationController
  include DtaStaticBuilder

  before_action :get_latest_content

  before_action :set_nav_heading

  def index
    @errors=[]
    @show_captcha_v2 = true

    if request.post?
      if validate_email

        Notifier.feedback(params).deliver_now
        if Settings.mailchimp_key.present? and params[:email].present? and params[:name].present? and params[:newsletter].present? and params[:newsletter] == 'yes'
          begin
            gibbon = Gibbon::Request.new(api_key: Settings.mailchimp_key)
            if Settings.dta_config["proxy_host"].present?
              gibbon.proxy = "http://#{Settings.dta_config['proxy_host']}:#{Settings.dta_config['proxy_port']}"
            end
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
        puts "EMAIL WAS SENT HERE: #{params[:email]} -- #{params[:message]}"
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

    captcha_result_v3 = verify_recaptcha(action: 'contact', minimum_score: 0.35, secret_key: Settings.recaptcha_secret_key_v3)
    captcha_result_v3 = false # Temporary disable?

    unless captcha_result_v3
      if verify_recaptcha
        @show_captcha_v2 = false
      else
        @show_captcha_v2 = true
        @errors << 'Captcha failed. Please try submitting your message again with the added checkbox captcha.'
        #@errors << 'Background recaptcha failed. Please try submitting your message again with the added checkbox captcha.'
      end
    end

    puts @errors.to_s

    @errors.empty?
  end
end
