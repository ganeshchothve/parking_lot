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
//= require highcharts


// Highcharts.chart('total_brokerage', {

//   chart: {
//     type: 'column'
//   },

//   title: {
//     text: 'Total fruit consumption, grouped by gender'
//   },

//   xAxis: {
//     categories: ['Oct 2020', 'Nov 2020', 'Dec 2020']
//   },

//   yAxis: {
//     allowDecimals: false,
//     min: 0,
//     title: {
//       text: 'Number of fruits'
//     }
//   },

//   tooltip: {
//     formatter: function () {
//       return '<b>' + this.x + '</b><br/>' +
//         this.series.name + ': ' + this.y + '<br/>' +
//         'Total: ' + this.point.stackTotal;
//     }
//   },

//   plotOptions: {
//     column: {
//       stacking: 'normal'
//     }
//   },

//   series: [{
//     name: 'Paid',
//     data: [5, 3, 4, 7, 2]
//   }, {
//     name: 'Pending',
//     data: [3, 4, 4, 2, 5]
//   }]
// });
// Highcharts.chart('total_brokerage', {
//   chart: {
//     type: 'column'
//   },
//   title: {
//     text: 'Stacked bar chart'
//   },
//   xAxis: {
//     categories: ['Oct 2020', 'Nov 2020', 'Dec 2020']
//   },
//   yAxis: {
//     min: 0,
//     title: {
//       text: 'Total fruit consumption'
//     }
//   },
//   legend: {
//     reversed: true
//   },
//   plotOptions: {
//     series: {
//       stacking: 'normal'
//     }
//   },
//   series: [{
//     name: 'Paid',
//     data: [5, 3, 4, 7, 2]
//   }, {
//     name: 'Pending',
//     data: [2, 2, 3, 2, 1]
//   }]
// });
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

  $('.prjt-menu a').on("click", function () {
    console.log('click');
    // if (!$(this).hasClass('extLink')) {
    var href = $(this).attr("rel");
    var gap = 110;

    $('html,body').animate({
      scrollTop: $("#" + href).offset().top - gap
    });
    // }
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

// var childrenSelector = $(".nav-tabs a");
//  var aChildren = $(".nav-tabs a"); // find the a children of the list items
//  if (window_wt <= 700)
//      var gap = 60; // $(".header-wrapper").outerHeight(); //Navigation height
//  else
//      var gap = 70;
//  var aArray = []; // create the empty aArray
//  for (var i = 0; i < childrenSelector.length; i++) {
//      var aChild = aChildren[i];
//      if (!$(aChild).hasClass('extLink')) {
//          if ($(aChild).attr('rel')) {
//              var ahref = $(aChild).attr('rel');
//              aArray.push(ahref);
//          }
//      }
//  }
//  //On Scroll - Add class active to active tab
//  $(window).scroll(function() {
//      var windowPos = $(".prjt-content-list").scrollTop(); // get the offset of the window from the top of page
//      var windowHeight = $('.prjt-content-list').height(); // get the height of the window
//      var docHeight = $(document).height();
//      for (i = 0; i < aArray.length; i++) {
//          var theID = aArray[i];
//          var divPos = $("#" + theID).offset().top; // get the offset of the div from the top of page
//          var divHeight = $("#" + theID).outerHeight(); // get the height of the div in question
//          if (windowPos >= (divPos - gap) && windowPos < ((divPos - gap) + divHeight)) {
//              if (!$("a[rel='" + theID + "']").hasClass("active")) {
//                  $("a[rel='" + theID + "']").addClass("active");
//              }
//          } else {
//              $("a[rel='" + theID + "']").removeClass("active");
//          }
//      }

//      //If document has scrolled to the end. Add active class to the last navigation menu
//      if (windowPos + windowHeight == docHeight) {
//          if (!$(".nav-tabs a:not(.extLink):last-child").hasClass("active")) {
//              var navActiveCurrent = $(".active").attr("rel");
//              $("a[rel='" + navActiveCurrent + "']").removeClass("active");
//              $(".nav-tabs a:not(.extLink):last-child").addClass("active");
//          }
//      }
//  });