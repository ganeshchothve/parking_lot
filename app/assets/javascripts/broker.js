//= require rails-ujs
//= require jquery3
//= require bootstrap/bootstrap
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
//= require fontawesome-all
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

$(document).ready(function(){
	$('.header-search-icon').click(function(){
		$('.icon-search').toggleClass('close');
	});
  $('.nav-tabs button').click(function(){
    var curnt_tab = $(this).attr('aria-controls');
    $('.nav-tabs button').removeClass('active');
    $('.tab-content .tab-pane').removeClass('show active');
    $(this).addClass('active');
    $('#'+curnt_tab).addClass('show active');
  });
});