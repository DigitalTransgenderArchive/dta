module CollectionsHelper

  # link to view all items in a collection
  def link_to_all_col_items(col_title, institution_name=nil, link_class)
    facet_params = {blacklight_config.collection_field => [col_title]}
    facet_params[blacklight_config.institution_field] = institution_name if institution_name
#, :sort=>"dta_sortable_date_dtsi+asc%2C+title_primary_ssort+asc"
    link_to(t('blacklight.collections.browse.all'),
            search_catalog_path(:f => facet_params, :sort=>"dta_sortable_date_dtsi asc, title_primary_ssort asc"),
            :class => link_class)
    # search_catalog_url ?
    # catalog_index_path
  end

  # link to collections starting with a specific letter
  def link_to_cols_start_with(letter)
    link_to(letter,
            #collections_public_path(:q => 'title_info_primary_ssort:' + letter + '*'),
            collections_path(:filter=>letter),
            :class => 'col_a-z_link')
  end

  # whether the A-Z link menu should be displayed in collections#index
  def should_render_col_az?
    true
  end

  def make_links_clickable(str)
    match_strings = []
    local_str = str.clone

    while local_str.match(/https?:\/\/(?:www\.|(?!www))[^\s\.]+\.[^\s]{2,}|www\.[^\s]+\.[^\s]{2,}/) do
      match_strings << local_str.match(/https?:\/\/(?:www\.|(?!www))[^\s\.]+\.[^\s]{2,}|www\.[^\s]+\.[^\s]{2,}/)
      local_str.gsub!(match_strings[-1].to_s, '')
    end

    match_strings.each do |match_string|
      str.gsub!(match_string.to_s, "<a href='#{match_string.to_s}' title='Click here to visit #{match_string.to_s} (new window)' target='_blank'>#{match_string.to_s}</a>")
    end
    str
  end


  #COPIED FROM HYDRA COLLECTIONS COLLECTIONS HELPER
  # Displays the Collections create collection button.  Put this in your search result page template.  We recommend putting it in catalog/_sort_and_per_page.html.erb
  def button_for_create_collection(label = 'Create Collection')
    render partial:'/collections/button_create_collection', locals:{label:label}
  end

  # Displays the Collections update collection button.  Put this in your search result page template.  We recommend putting it in catalog/_sort_and_per_page.html.erb
  def button_for_update_collection(label = 'Update Collection', collection_id = 'collection_replace_id' )
    render partial:'/collections/button_for_update_collection', locals:{label:label, collection_id:collection_id}
  end

  # Displays the Collections delete collection button.  Put this in your search result page for each collection found.
  def button_for_delete_collection(collection, label = 'Delete Collection', confirm = 'Are you sure?')
    render partial:'/collections/button_for_delete_collection', locals:{collection:collection,label:label, confirm:confirm}
  end

  def button_for_remove_from_collection(document, label = 'Remove From Collection')
    render partial:'/collections/button_remove_from_collection', locals:{label:label, document:document}
  end

  def button_for_remove_selected_from_collection(collection, label = 'Remove From Collection')
    render partial:'/collections/button_for_remove_selected_from_collection', locals:{collection:collection, label:label}
  end


  # add hidden fields to a form for removing a single document from a collection
  def single_item_action_remove_form_fields(form, document)
    single_item_action_form_fields(form, document, "remove")
  end

  # add hidden fields to a form for adding a single document to a collection
  def single_item_action_add_form_fields(form, document)
    single_item_action_form_fields(form, document, "add")
  end

  # add hidden fields to a form for performing an action on a single document on a collection
  def single_item_action_form_fields(form, document, action)
    render partial:'/collections/single_item_action_fields', locals:{form:form, document:document, action: action}
  end

  def hidden_collection_members
    _erbout = ''
    if params[:batch_document_ids].present?
      params[:batch_document_ids].each do |batch_item|
        _erbout.concat hidden_field_tag("batch_document_ids[]", batch_item)
      end
    end
    _erbout.html_safe
  end

end
