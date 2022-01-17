class AutocompleteController < ActionController::Base

  # This will need to be fixed
  def publishers
    publisher_start_with = {}
    publisher_includes = {}

    params[:q] ||= ''
    original_param = params[:q]
    params[:q] = params[:q].downcase

    GenericObject.all.pluck(:publishers).each do |publishers|
      publishers.each do |publisher|
        if publisher.downcase.starts_with? params[:q]
          publisher_start_with[publisher] ||= 0
          publisher_start_with[publisher] += 1
        elsif publisher.downcase.include? params[:q]
          publisher_includes[publisher] ||= 0
          publisher_includes[publisher] += 1
        end
      end
    end

    publisher_array = publisher_start_with.sort_by { |key, val| val }.reverse

    # Don't use + as eliminates sorting
    publisher_includes.sort_by { |key, val| val }.reverse.each do |pub_includes|
      publisher_array << pub_includes
    end

    unless (publisher_array.select {|arr| arr[0].downcase == params[:q] }).present?
      publisher_array.prepend([original_param, "Add New"])
    end

    publisher_array = publisher_array.take(params[:per_page].to_i) if params.has_key? :per_page

    items = publisher_array.map do |u|
      {
          id: u[0],
          text: "#{u[0]} (#{u[1]})"
      }
    end

    render json: {
        total_count: items.size,
        items: items
    }
  end

  def contributors
    params[:q] ||= ''
    original_param = params[:q]
    params[:q] = params[:q].downcase

    contributors_start_with = GenericObject.joins(:contributors).group('contributors.label').where('lower(contributors.label) like ?', "#{params[:q]}%").size
    contributors_includes = GenericObject.joins(:contributors).group('contributors.label').where('lower(contributors.label) like ?', "%#{params[:q]}%").size

    contributors_array = contributors_start_with.sort_by { |key, val| val }.reverse

    # Don't use + as eliminates sorting
    contributors_includes.sort_by { |key, val| val }.reverse.each do |contrib_includes|
      contributors_array << contrib_includes unless contributors_array.select { |arr| arr == contrib_includes }
    end

    unless (contributors_array.select {|arr| arr[0].downcase == params[:q] }).present?
      contributors_array.prepend([original_param, "Add New"])
    end

    contributors_array = contributors_array.take(params[:per_page].to_i) if params.has_key? :per_page

    items = contributors_array.map do |u|
      {
          id: u[0],
          text: "#{u[0]} (#{u[1]})"
      }
    end

    render json: {
        total_count: items.size,
        items: items
    }
  end

  def creators
    params[:q] ||= ''
    original_param = params[:q]
    params[:q] = params[:q].downcase

    creators_start_with = GenericObject.joins(:creators).group('creators.label').where('lower(creators.label) like ?', "#{params[:q]}%").size
    creators_includes = GenericObject.joins(:creators).group('creators.label').where('lower(creators.label) like ?', "%#{params[:q]}%").size

    creators_array = creators_start_with.sort_by { |key, val| val }.reverse

    # Don't use + as eliminates sorting
    creators_includes.sort_by { |key, val| val }.reverse.each do |create_includes|
      creators_array << create_includes unless creators_array.select { |arr| arr == create_includes }
    end

    unless (creators_array.select {|arr| arr[0].downcase == params[:q] }).present?
      creators_array.prepend([original_param, "Add New"])
    end

    creators_array = creators_array.take(params[:per_page].to_i) if params.has_key? :per_page

    items = creators_array.map do |u|
      {
          id: u[0],
          text: "#{u[0]} (#{u[1]})"
      }
    end

    render json: {
        total_count: items.size,
        items: items
    }
  end

  def homosaurus_subject
    authority_result = HomosaurusAutocomplete.find(params[:q])
    authority_result = [] if authority_result.blank?

    render json: authority_result
  end

  def homosaurus_v2_subject
    authority_result = HomosaurusV2Autocomplete.find(params[:q])
    authority_result = [] if authority_result.blank?

    render json: authority_result
  end

  def homosaurus_uri_subject
    authority_result = HomosaurusUriAutocomplete.find(params[:q])
    authority_result = [] if authority_result.blank?

    render json: authority_result
  end

  def lcsh_subject
    authority_check = Mei::Loc.new('subjects')
    authority_result = authority_check.search(params[:q]) #URI escaping doesn't work for Baseball fields?
    authority_result = [] if authority_result.blank?

    render json: authority_result
  end

  def combined_subject
    authority_result_homo = HomosaurusAutocomplete.find(params[:q])
    authority_result_homo = [] if authority_result_homo.blank?

    #authority_check = Mei::Loc.new('subjects')
    #authority_result_lcsh = authority_check.search(params[:q]) #URI escaping doesn't work for Baseball fields?
    authority_result_lcsh = [] if authority_result_lcsh.blank?

    authority_result_homo + authority_result_lcsh
  end

  def exact_match
    render json: combined_subject
  end

  def close_match
    render json: combined_subject
  end

  def geonames_subject
    authority_check = Mei::Geonames.new(params[:e])
    authority_result = authority_check.search(params[:q]) #URI escaping doesn't work for Baseball fields?
    authority_result = [] if authority_result.blank?

    render json: authority_result
  end

  def other_subject
    params[:q] ||= ''
    original_param = params[:q]
    params[:q] = params[:q].downcase

    subjects_start_with = GenericObject.joins(:other_subjects).group('other_subjects.label').where('lower(other_subjects.label) like ?', "#{params[:q]}%").size
    subjects_includes = GenericObject.joins(:other_subjects).group('other_subjects.label').where('lower(other_subjects.label) like ?', "%#{params[:q]}%").size

    subjects_array = subjects_start_with.sort_by { |key, val| val }.reverse

    # Don't use + as eliminates sorting
    subjects_includes.sort_by { |key, val| val }.reverse.each do |subject_includes|
      subjects_array << subjects_includes unless subjects_array.select { |arr| arr == subjects_includes }
    end

    unless (subjects_array.select {|arr| arr[0].downcase == params[:q] }).present?
      subjects_array.prepend([original_param, "Add New"])
    end

    subjects_array = subjects_array.take(params[:per_page].to_i) if params.has_key? :per_page

    items = subjects_array.map do |u|
      {
          id: u[0],
          text: "#{u[0]} (#{u[1]})"
      }
    end

    render json: {
        total_count: items.size,
        items: items
    }
  end

  def languages
    params[:q] ||= ''
    #original_param = params[:q]
    #params[:q] = params[:q].downcase

    authority_check = Qa::Authorities::Loc.subauthority_for('iso639-2')
    authority_result = authority_check.search(URI.escape(params[:q])+'*')
    if authority_result.present?
      authority_result.map! { |item| { text: item["label"], id: item["id"].gsub('info:lc', 'http://id.loc.gov') } }
    else
      authority_result = []
    end

    render json: {
        total_count: authority_result.size,
        items: authority_result
    }
  end

  def homosaurus_subject_partial
    params[:q] ||= ''
    original_param = params[:q]
    params[:q] = params[:q].downcase

    homosaurus_start_with = HomosaurusSubject.includes(:object_homosaurus_subject).where('lower(homosaurus_subjects.label) like ?', "#{params[:q]}%")
    homosaurus_includes = HomosaurusSubject.includes(:object_homosaurus_subject).where('lower(homosaurus_subjects.label) like ?', "%#{params[:q]}%")

    homosaurus_start_with.sort_by{ |val| val.object_homosaurus_subject.size }.reverse
    homosaurus_includes.sort_by{ |val| val.object_homosaurus_subject.size }.reverse

    homosaurus_arr1 = homosaurus_start_with.map do |homo| { id: homo.uri, text: "#{homo.label} (#{homo.object_homosaurus_subject.size})" } end
    homosaurus_arr2 = homosaurus_includes.map do |homo| { id: homo.uri, text: "#{homo.label} (#{homo.object_homosaurus_subject.size})" } end

    # Don't use + as eliminates sorting
    homosaurus_arr2.each do |homo_includes|
      homosaurus_arr1 << homo_includes unless homosaurus_arr1.select { |arr| arr == homo_includes }
    end

    homosaurus_arr1 = homosaurus_arr1.take(params[:per_page].to_i) if params.has_key? :per_page

    items = homosaurus_arr1.map do |u|
      {
          id: u[:id],
          text: "#{u[:text]}"
      }
    end

    render json: {
        total_count: items.size,
        items: items
    }
  end

  def dates
    params[:q] ||= ''

    date = Date.edtf(params[:q])

    if date.nil?
      render json: {
          total_count: 0,
          items: [{}]
      }
    else
      readable = self.humanize_edtf(date)
      items = [{id: params[:q], text: "#{params[:q]} (Display: #{readable})"}]
      render json: {
          total_count: items.size,
          items: items
      }
    end


  end

  def humanize_edtf(edtf_date)
    humanized_edtf = edtf_date.humanize
    # Capitalize the seasons
    humanized_edtf = humanized_edtf.split(' ').map! { |word| ['summer', 'winter', 'autumn', 'spring'].include?(word) ? word.capitalize : word }.join(' ')

    #Abbreviate the Months
    humanized_edtf = humanized_edtf.split(' ').map! { |word|  Date::MONTHNAMES.include?(word) ? "#{Date::ABBR_MONTHNAMES[Date::MONTHNAMES.find_index(word)]}." : word }.join(' ')

    #Remove period from "May"
    humanized_edtf = humanized_edtf.split(' ').map! { |word|  word.include?('May.') ? "May" : word }.join(' ')

    humanized_edtf
  end
end
