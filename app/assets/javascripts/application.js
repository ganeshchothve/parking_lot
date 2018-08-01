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
//= require rails-ujs
//= require jquery3
//= require popper
//= require bootstrap-sprockets
//= require noty
//= require lodash
//= require intlTelInput
//= require jquery.ui.widget
//= require jquery.validate
//= require moment
//= require jquery.crs
//= require jquery.fileupload
//= require jquery.blockUI.js
//= require selectize
//= require plugins/array_field
//= require plugins/file_uploader
//= require daterangepicker
//= require fontawesome-all
//= require bootstrap-datetimepicker.min
//= require utils
//= require file-icon
//= require form-initializer
//= require validator
//= require registration
//= require otp_based_login

$.ajaxSetup({
  headers: {
    'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')
  }
});
$(document).ready(function(){
	$(".colorbox-init").colorbox({
		maxWidth: "90%",
		maxHeight: "90%",
		onComplete: function(){
			$('#cboxLoadedContent').zoom();
		}
	});
})
