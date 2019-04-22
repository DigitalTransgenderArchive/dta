class PostsController < ApplicationController
  include DtaStaticBuilder

  before_action :get_latest_content

  before_action :set_nav_heading

  before_action :build_global_tag_list

  before_action :verify_admin, only: [:new, :create, :edit, :update]

  def build_global_tag_list
    @tag_links = []
    tags = ActsAsTaggableOn::Tag.most_used(30)
    tags.each do |tag|
      if params[:tag].present? and tag.name == params[:tag]
        @tag_links << "#{tag} (#{tag.taggings_count})"
      else
        @tag_links << (view_context.link_to "#{tag} (#{tag.taggings_count})", "#{posts_path}?tag=#{tag}", class: "#{'document-title'}")
      end

    end

  end

  def index
    @current_tag = params[:tag]

    if current_user.present? and current_user.admin?
      #@posts = Posts.all.order("created DESC")
      if params[:tag].present?
        @posts = Posts.tagged_with(params[:tag]).order("created DESC").page params[:page]
      else
        @posts = Posts.order("created DESC").page params[:page]
      end

    else
      if params[:tag].present?
        @posts = Posts.tagged_with(params[:tag]).where(:published=>true).order("created DESC").page params[:page]
      else
        @posts = Posts.where(:published=>true).order("created DESC").page params[:page]
      end

    end

    respond_to do |format|
      format.html { }
      format.rss { render :layout => false }
    end

  end

  def new
    @post = Posts.new
    gon.compiled_application_css = Rails.application.assets["application.css"].to_s
  end

  def edit
    @post = Posts.friendly.find(params[:id])
    gon.compiled_application_css = Rails.application.assets["application.css"].to_s
  end

  def update
    @post = Posts.friendly.find(params[:id])

    if !current_user.superuser? && @post.published
      redirect_to posts_path, notice: "Unauthorized update of a published post."
    else

      params[:posts][:published] = false unless current_user.superuser?

      @post.update(post_params)

      potential_image = @post.content.match(/<img[\w \.\/\'\"\=&#\-_\:“”;,—–\s\(\)\?]+>/)
      if potential_image.present?

        result = potential_image.to_s.match(/src\=[\'\"][\w\.\/\-_\:]+[\'\"]/)
        if result.present?
          @post.thumbnail = result.to_s.gsub("src=", "").gsub('"', '').gsub('"', '')
        end
      end


      if @post.save
        redirect_to post_path(:id => @post.slug), notice: "Post was updated!"
      else
        redirect_to posts_path, notice: "Could not update post"
      end
    end
  end

  def create
    @post = Posts.new(post_params)
    current_time = Time.now

    @post.created_ym = current_time.strftime("%Y-%m")
    @post.created_ymd = current_time.strftime("%Y-%m-%d")
    @post.created = current_time
    @post.updated = current_time
    potential_image = @post.content.match(/<img[\w \.\/\'\"\=&#\-_\:“”;,—–\s\(\)\?]+>/)
    if potential_image.present?

      result = potential_image.to_s.match(/src\=[\'\"][\w\.\/\-_\:]+[\'\"]/)
      if result.present?
        @post.thumbnail = result.to_s.gsub("src=", "").gsub('"', '').gsub('"', '')
      end
    end
    @post.user = current_user.email


      @post.published = false unless current_user.superuser?

=begin
    if params[:homosaurus][:broader_ids].present?
      params[:homosaurus][:broader_ids].each do |broader|
        if broader.present?
          broader_object = Homosaurus.find(broader)
          @homosaurus.broader = @homosaurus.broader + [broader_object]
          broader_object.narrower = broader_object.narrower + [@homosaurus]
          broader_object.save
        end
      end
    end
=end


    if @post.save
      redirect_to post_path(:id => @post.slug)
    else
      #redirect_to post_path(:id => @post.id)
      redirect_to new_post_path, notice: "Could not create post"
    end
  end

  def show
    @post = Posts.friendly.find(params[:id])

    @next_post = @post.next
    @prev_post = @post.prev

    @tag_links = []
    @post.tags.each do |tag|
      @tag_links << (view_context.link_to "#{tag} (#{tag.taggings_count})", "#{posts_path}?tag=#{tag}", class: "#{'document-title'}")
    end

    respond_to do |format|
      format.html
      #format.nt { render body: @homosaurus.full_graph.dump(:ntriples), :content_type => Mime::NT }
      #format.jsonld { render body: @homosaurus.full_graph.dump(:jsonld, standard_prefixes: true), :content_type => Mime::JSONLD }
    end
  end


  def post_params
    params.require(:posts).permit(:content, :title, :published, :abstract, :tag_list)
  end

  def set_nav_heading
    @nav_section = 'About'
    @nav_items = []

    if current_user.present? and current_user.superuser?
      nav_items_raw = Abouts.all.order("link_order")
    else
      nav_items_raw = Abouts.where(:published=>true).order("link_order")
    end

=begin
    nav_items_raw.each do |nav_item|
      @nav_items << (ActionController::Base.helpers.link_to nav_item.title, about_path(:id=>nav_item))
    end
=end

    nav_items_raw.each do |nav_item|
      if 'news' == nav_item.url_label
        if params[:id].present? and params[:id]
          @nav_items << "<a href='#{posts_path}' class='active'>#{nav_item.title}</a><ul><li>#{Posts.friendly.find(params[:id]).title}</li></ul>"
        else
          #@nav_items << nav_item.title
          @nav_items << (ActionController::Base.helpers.link_to nav_item.title, about_path(:id=>nav_item), {class: 'active'})
        end
      else
        @nav_items << (ActionController::Base.helpers.link_to nav_item.title, about_path(:id=>nav_item))
      end
    end
  end
end
