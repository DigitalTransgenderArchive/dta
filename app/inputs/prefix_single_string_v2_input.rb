class PrefixSingleStringV2Input < SingleBaseInput

  def inner_wrapper
    <<-HTML
          <li class="field-wrapper">
             <div class="input-group col-sm-12">
               <span class="input-group-addon">http://homosaurus.org/v2/</span>
              #{yield}
              </div>
          </li>
    HTML
  end

  def input_type
    #'multi_value'.freeze
    'no_repeat_field_value'.freeze
  end
end