class AboutsController < ApplicationController
  include DtaStaticBuilder

  before_action :get_latest_content

  before_action :set_nav_heading

  before_action :verify_superuser, only: [:new, :create, :edit, :update]

  #layout 'static_layout'

  def index
    @nav_items[0] = "What is this?"
  end

  def project
    @nav_items[1] = "Project Information"
  end

  def news
    @nav_items[2] = "News"
  end

  def team
    @nav_items[3] = "Our Team"
  end

  def board
    @nav_items[4] = "Advisory Board"
  end

  def policies
    @nav_items[5] = "Policies"
  end


  def contact
    @nav_items[6] = "Contact Us"
  end

  def edit
    @page = Abouts.find(params[:id])
    gon.compiled_application_css = Rails.application.assets["application.css"].to_s
  end

  def update
    @page = Abouts.find(params[:id])
    @page.destroy!
    @page = Abouts.new(page_params)
    #@page.update(page_params)

    if @page.save
      redirect_to about_path(:id => @page), notice: "Page was updated!"
    else
      redirect_to abouts_path, notice: "Could not update page"
    end
  end

  def new
    @page = Abouts.new
    gon.compiled_application_css = Rails.application.assets["application.css"].to_s
  end

  def create
    @page = Abouts.new(page_params)

    if @page.save
      redirect_to about_path(:id => @page.id)
    else
      #redirect_to post_path(:id => @post.id)
      redirect_to new_about_path, notice: "Could not create about page"
    end
  end

  def show
    if params[:id] == 'news'
      params.delete(:id)
      redirect_to posts_path
    else
      @page = Abouts.find(params[:id])
    end
  end


  def feedback
    @page = Abouts.find('contact')
    @errors=[]
    if request.post?
      if validate_email
        Notifier.feedback(params).deliver_now
        redirect_to feedback_complete_path
      end
    end
  end

  def feedback_complete
    @page = Abouts.find('contact')
  end

  def subscribe
    @page = Abouts.find('contact')
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
      @errors << t('blacklight.feedback.need_message')
    end
    #unless simple_captcha_valid?
    #  @errors << 'Captcha did not match'
    #end
    @errors.empty?
  end

  def set_nav_heading
    @nav_section = 'About'
    @nav_items = []

    if current_user.present? and current_user.superuser?
      nav_items_raw = Abouts.all.order("link_order")
    else
      nav_items_raw = Abouts.where(:published=>true).order("link_order")
    end



    nav_items_raw.each do |nav_item|
      if nav_item.url_label == 'contact'
=begin
        if params[:id].present? and params[:id] == nav_item.url_label
          @nav_items << "<a href='#{about_path(:id=>nav_item)}' class='active'>#{nav_item.title}</a><ul><li><a href='#{feedback_path}'>Email Us</a></li><li><a href='#{subscribe_path}'>Mailing List</a></li></ul>"
        elsif request.env['PATH_INFO'] == '/feedback' || request.env['PATH_INFO'] == '/feedback_complete'
          @nav_items << "<a href='#{about_path(:id=>nav_item.url_label)}' class='active'>#{nav_item.title}</a><ul><li>Email Us</li><li><a href='#{subscribe_path}'>Mailing List</a></li></ul>"
        elsif request.env['PATH_INFO'] == '/subscribe'
          @nav_items << "<a href='#{about_path(:id=>nav_item.url_label)}' class='active'>#{nav_item.title}</a><ul><li><a href='#{feedback_path}'>Email Us</a></li><li>Mailing List</li></ul>"
        else
          @nav_items << (ActionController::Base.helpers.link_to nav_item.title, about_path(:id=>nav_item))
        end
=end
      elsif params[:id].present? and params[:id] == nav_item.url_label
        #@nav_items << nav_item.title
        @nav_items << (ActionController::Base.helpers.link_to nav_item.title, about_path(:id=>nav_item), {class: 'active'})
      elsif nav_item.url_label == 'news'
        @nav_items << "<a href='#{posts_path}'>#{nav_item.title}</a>"

      else
        @nav_items << (ActionController::Base.helpers.link_to nav_item.title, about_path(:id=>nav_item))
      end

    end

    #@nav_items << (ActionController::Base.helpers.link_to 'What is this?', about_path)
=begin
    @nav_items << (ActionController::Base.helpers.link_to 'Project Information', about_project_path)
    @nav_items << (ActionController::Base.helpers.link_to 'News', posts_path)
    @nav_items << (ActionController::Base.helpers.link_to 'Our Team', about_team_path)
    @nav_items << (ActionController::Base.helpers.link_to 'Advisory Board', about_board_path)
    @nav_items << (ActionController::Base.helpers.link_to 'Policies', about_policies_path)
    @nav_items << (ActionController::Base.helpers.link_to 'Contact Us', about_contact_path)
=end
  end

  def page_params
    params.require(:page).permit(:url_label, :title, :published, :content, :link_order)
  end


end
