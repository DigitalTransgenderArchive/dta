class AutocompleteController

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

    publisher_array << [original_param, '(Add New)'] unless publisher_array.select {|arr| arr[0].downcase == params[:q] }

    publishers_array = publishers_array.take(params[:per_page]) if params.has_key? :per_page

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

    contributors_array << [original_param, '(Add New)'] unless contributors_array.select {|arr| arr[0].downcase == params[:q] }

    contributors_array = contributors_array.take(params[:per_page]) if params.has_key? :per_page

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

    creators_array << [original_param, '(Add New)'] unless creators_array.select {|arr| arr[0].downcase == params[:q] }

    creators_array = creators_array.take(params[:per_page]) if params.has_key? :per_page

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
      items = [{id: date, text: "#{date} (#{readable})"}]
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
