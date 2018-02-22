class DatesLookupInput < MultiSelectPickerInput
  def buffer_each(collection)
    collection.each_with_object('').with_index do |(value, buffer), index|
      #buffer << yield(value, index) if value.match(/http:\/\/homosaurus\.org\/terms\//) || value.blank?
      if value.blank? and !@rendered_first_element
        buffer << yield(value, index)
      elsif value.present?
        date = Date.edtf(value)
        readable = self.humanize_edtf(date)
        buffer << yield([value, "#{value} (Display: #{readable})"], index)
      end
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
