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
//= require selectize_infinite_scroll
//= require plugins/array_field
//= require plugins/file_uploader
//= require daterangepicker
//= require plugins/smooth_zoom
//= require font-awesome/js/all
//= require bootstrap-datetimepicker.min
//= require utils
//= require file-icon
//= require form-initializer
//= require validator
//= require registration
//= require otp_based_login
//= require amura
//= require plugins/jsencrypt
//= require jquery-ui.min

var window_wt = $(window).width();
var window_ht = $(window).height();
$(document).ready(function () {
  $('.header-search-icon').click(function () {
    $('.icon-search').toggleClass('close');
  });
  // $('.prjt-content-list').scrollspy({ target: '#prjt-menu' })
  // $('.tab-link a').click(function(){
  //   var curnt_tab = $(this).attr('rel');
  //   $('.tab-link a').removeClass('active');
  //   $('.tab-content .tab-inner').removeClass('show active');
  //   $(this).addClass('active');
  //   $('#'+curnt_tab).addClass('show active');
  // });
  $('.pwd-btn').click(function () {
    if ($(this).hasClass('show-pwd')) {
      $(this).removeClass('show-pwd').addClass('hide-pwd')
      $(this).children().removeClass('fa-eye-slash').addClass('fa-eye');
      $('.pwd-field').attr('type', 'text');
    } else {
      $('.pwd-field').attr('type', 'password');
      $(this).removeClass('hide-pwd').addClass('show-pwd')
      $(this).children().removeClass('fa-eye').addClass('fa-eye-slash');
    }
  });

  var tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'))
  var tooltipList = tooltipTriggerList.map(function (tooltipTriggerEl) {
    return new bootstrap.Tooltip(tooltipTriggerEl)
  })

  var popoverTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="popover"]'))
  var popoverList = popoverTriggerList.map(function (popoverTriggerEl) {
    return new bootstrap.Popover(popoverTriggerEl)
  });
  var popover = new bootstrap.Popover(document.querySelector('.popover-dismiss'), {
    trigger: 'focus'
  })
  var header = $("body");
  $(window).scroll(function () {
    var windowScroll = $(window).scrollTop();
    var menuScroll = $('.prjt-menu').offset().top - 80;
    if (windowScroll >= menuScroll) {
      header.addClass("fixed-subheader");
    }
    if (windowScroll <= 225) {
      header.removeClass("fixed-subheader");
    }
  });
});

