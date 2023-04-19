class HomosaurusLookupInput < MeiMultiLookupInput
  def inner_wrapper
    <<-HTML
          <li class="field-wrapper">
             <div class="input-group col-sm-12">
              #{yield}
              <span class="input-group-btn">
                 <button class="btn btn-danger" data-js-delete-audits-field="true" type="button", tabindex="-1">-</button>
              </span>
              </div>
          </li>
    HTML
  end

  def buffer_each(collection)
    collection.each_with_object('').with_index do |(value, buffer), index|
      #buffer << yield(value, index) if value.match(/http:\/\/homosaurus\.org\/terms\//) || value.blank?
      #if value.uri.match(/http:\/\/homosaurus\.org\/terms\//)
      if value.blank? and !@rendered_first_element
        buffer << yield(value, index)
      elsif value.present? && value.respond_to?(:uri)
        buffer << yield("#{value.label} (#{value.uri})", index)
      elsif value.present?
        h = HomosaurusSubject.find_by(uri: value)
        buffer << yield("#{h.label} (#{h.uri})", index)
      end
    end
  end

end
