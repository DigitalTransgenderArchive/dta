class Admin::AdminController < ApplicationController
  protect_from_forgery prepend: true

  def self.controller_path
    "admin"
  end

  def carousel_edit
    @carousels = []
    Carousel.all.each do |c|
      @carousels << {collection_pid: c.collection_pid, image_pid: c.image_pid, description: c.description}
    end
    (Carousel.count..5).each do |i|
      @carousels << {collection_pid: '', image_pid: '', description: ''}
    end

    render "admin/carousel_edit"
  end

  def carousel_update
    f = params[:carousel]
    @new_c = []
    (0..4).each do |index|
      if f[:collection_pid][index].strip.present?
        if f[:image_pid][index].strip.blank? || f[:description][index].strip.blank?
          raise 'Mismatch?'
        end

        coll_obj = Coll.find_by(pid: f[:collection_pid][index].strip)
        img_obj = GenericObject.find_by(pid: f[:image_pid][index].strip)
        raise "Object doesn't exist" if img_obj.blank? || coll_obj.blank?

        @new_c << { collection_pid: f[:collection_pid][index].strip,
                    image_pid: f[:image_pid][index].strip,
                    title: coll_obj.title,
                    iiif: "/downloads/#{f[:image_pid][index].strip}?file=carousel",
                    description: f[:description][index].strip}

      end
    end

    Carousel.transaction do
      Carousel.all.destroy_all
      @new_c.each do |c|
        Carousel.create(collection_pid: c[:collection_pid], image_pid: c[:image_pid], title: c[:title], iiif: c[:iiif], description: c[:description])
      end
    end

    flash[:success] = "The carousel was updated!"
    redirect_to root_path
  end


end
