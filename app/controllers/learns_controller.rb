class LearnsController < ApplicationController
  include DtaStaticBuilder

  before_action :get_latest_content

  before_action :set_nav_heading

  before_action :verify_superuser, only: [:new, :create, :edit, :update]

  #layout 'static_layout'

  def edit
    @page = Learns.find(params[:id])
    gon.compiled_application_css = Rails.application.assets["application.css"].to_s
  end

  def update
    @page = Learns.find(params[:id])
    @page.destroy!
    @page = Learns.new(page_params)
    #@page.update(page_params)

    if @page.save
      redirect_to learn_path(:id => @page), notice: "Page was updated!"
    else
      redirect_to learns_path, notice: "Could not update page"
    end
  end

  def new
    @page = Learns.new
    gon.compiled_application_css = Rails.application.assets["application.css"].to_s
  end

  def create
    @page = Learns.new(page_params)

    if @page.save
      redirect_to learn_path(:id => @page.id)
    else
      #redirect_to post_path(:id => @post.id)
      redirect_to new_learn_path, notice: "Could not create about page"
    end
  end

  def show
    if params[:id] == "guide"
      render "learns/guide"
    elsif params[:id] == "raceandethnicity"
        render "learns/raceandethnicity"
    else
      @page = Learns.find(params[:id])
    end

  end

  def set_nav_heading
    @nav_section = 'Learn'
    @nav_items = []

    if current_user.present? and current_user.superuser?
      nav_items_raw = Learns.all.order("link_order")
    else
      nav_items_raw = Learns.where(:published=>true).order("link_order")
    end

    nav_items_raw.each do |nav_item|

      if params[:id].present? and params[:id] == nav_item.url_label
        #@nav_items << nav_item.title
        @nav_items << (ActionController::Base.helpers.link_to nav_item.title, learn_path(:id=>nav_item), {class: 'active'})
      else
        @nav_items << (ActionController::Base.helpers.link_to nav_item.title, learn_path(:id=>nav_item))
      end

    end

  end

  def page_params
    params.require(:page).permit(:url_label, :title, :published, :content, :link_order)
  end


end
