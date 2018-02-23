// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, or any plugin's
// vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require rails-ujs
//= require activestorage
//= require turbolinks
// Required by Blacklight-Maps
//= require blacklight-maps
//
// Required by Blacklight
//= require blacklight/blacklight
//= require 'bootstrap/tooltip'
//= require 'bootstrap/popover'
//= require 'bootstrap/dropdown'
//= require 'bootstrap/button'
//= require 'bootstrap/tab'

// For blacklight_range_limit built-in JS, if you don't want it you don't need
// this:
//= require 'blacklight_range_limit'
//= require ahoy
//= require onmount
//= require 'openseadragon'
//= require ckeditor/init

//= require_tree .

$(document).on('ready turbolinks:load', function () { $.onmount() });
$(document).on('turbolinks:before-cache', function () { $.onmount.teardown() });
