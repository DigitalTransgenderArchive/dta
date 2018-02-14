$( document ).ready(function() {
   // initialize the bootstrap popovers
    $("a[data-toggle=popover]").popover({html: true})
        .click(function () {
            return false;
        });
});

function duplicate_field_click(event) {
    original_element = $(event.target).parent().parent().parent().children().children();
    original_id = original_element.attr("id");
    is_autocomplete_select2 = $(original_element).is("[endpoint]");

    if(is_autocomplete_select2) {
        cloned_element = $(event.target).parent().parent().parent().clone();
        cloned_element.find("span.select2-selection").remove();
    } else {
        cloned_element = $(event.target).parent().parent().parent().clone(true, true);
    }

    cloned_element.find("input").val("");
    cloned_element.find("textarea").val("");
    cloned_element.find("select").val("");

    $(event.target).parent().parent().parent().after(cloned_element);

    // Cloned elements with the select2 code need to have the duplicate buttons re-initialized
    if(is_autocomplete_select2) {
        $.onmount(); // Re-initialize the onclick handlers
    }

}

function delete_field_click(event) {
    local_field_name = $(event.target).parent().prev().prev().attr('name');

    //Current hack for lookup fields... may need more when I add hidden fields...
    if(local_field_name == undefined) {
        local_field_name = $(event.target).parent().prev().prev().prev().attr('name');
    }
    if ($('input[name*="' + local_field_name + '"]').length == 1) {
        $(event.target).parent().parent().parent().find("input").val("");
    } else if($('select[name*="' + local_field_name + '"]').length == 1) {
        $(event.target).parent().parent().parent().find("select").val("");
    } else {
        $(event.target).parent().parent().parent().remove();
    }
}

$.onmount("[data-js-duplicate-audits-field]", function () {
    $(this).click(duplicate_field_click);
});

$.onmount("[data-js-delete-audits-field]", function () {
    $(this).click(delete_field_click);
});

$.onmount("[data-js-select-all-fields]", function () {
    var checkbox = $(this);

    $(checkbox).click(function() {
        var checked = $(this).prop('checked');
        $("input[name='" + $(this).attr('data-field-name') + "']").each(function() {
            $(this).prop('checked', checked);
        })
    });
});

$.onmount("[data-js-toggle-disable-form-field]", function () {
    var checkbox = $(this);

    $(checkbox).click(function() {
        var checked = $(this).prop('checked');

        // Handle textarea fields
        $("textarea[name='" + $(this).attr('data-field-name') + "']").each(function() {
            $(this).prop('disabled', checked);
        });

        // Check all other input field types
        $("input[name='" + $(this).attr('data-field-name') + "']").each(function() {
            $(this).prop('disabled', checked);
        })
    });
});

