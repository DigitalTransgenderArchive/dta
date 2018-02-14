module DtaStaticBuilder
  def get_latest_content
    @latest_documents = GenericFile.find_with_conditions("is_public_ssi:true", rows: '4', :sort => 'date_uploaded_dtsi desc' )

    @recent_posts = Posts.where(:published=>true).order("created DESC").limit(3)

    if current_user.present? and current_user.superuser?
      @about_section_links = Abouts.all.order("link_order")
    else
      @about_section_links = Abouts.where(:published=>true).order("link_order")
    end

    if current_user.present? and current_user.superuser?
      @learn_section_links = Learns.all.order("link_order")
    else
      @learn_section_links = Learns.where(:published=>true).order("link_order")
    end

  end
end
