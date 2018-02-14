class MeiMultiLookupInput < MultiBaseInput
  include WithHelpIcon

  # Overriding this so that the class is correct and the javascript for multivalue will work on this.
  def input_type
    'repeat_field_value'.freeze
  end

  def inner_wrapper
    <<-HTML
          <li class="field-wrapper">
             <div class="input-group col-sm-12">
              #{yield}

             <button style="width:auto;" type="button" class="btn btn-default" data-toggle="modal" data-target="#meiLookupModal_#{attribute_name}">Lookup</button>
              <span class="input-group-btn regular_audits_duplicate_span">
                <button class="btn btn-success" data-js-duplicate-audits-field="true" type="button">+</button>
              </span>
              <span class="input-group-btn">
                 <button class="btn btn-danger" data-js-delete-audits-field="true" type="button">-</button>
              </span>
              </div>
          </li>
    HTML
  end

  def build_field(value, index)
    options = build_field_options(value, index)
    if options.delete(:type) == 'textarea'.freeze
      @builder.text_area(attribute_name, options)
    else
      @builder.text_field(attribute_name, options)
    end
  end







end
