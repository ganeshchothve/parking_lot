$.validator.setDefaults({
  highlight: function(element) {
    $(element).closest('.mb-3').addClass('has-error');
  },
  unhighlight: function(element) {
    $(element).closest('.mb-3').removeClass('has-error');
  },
  errorElement: 'span',
  errorClass: 'help-block',
  errorPlacement: function(error, element) {
    if(element.parent('.input-group').length > 0) {
      error.insertAfter(element.parent());
    } else if(element.parent().hasClass("selectize-input")) {
      error.insertAfter(element.closest(".selectize-control"));
    } else if(element.hasClass("array-field")) {
      error.insertAfter(element.closest(".mb-3").find(".array-field-wrapper"));
    } else if(element.parent().hasClass("intl-tel-input")) {
      error.insertAfter(element.closest(".intl-tel-input"));
    } else {
      error.insertAfter(element);
    }
  },
  ignore: ":hidden:not([class~=selectized]), :hidden > .selectized, .selectize-control .selectize-input input"
});

$(document).ready(function(){
  // to ensure that this is only called after all other default trigger change events are fired in our Javascripts
  setTimeout(function(){
    $('.validate-form').find('input[type="text"], input[type="radio"], input[type="checkbox"], input[type="number"], textarea, select, input[type="email"]').change(function(){
      if(typeof window.onbeforeunload !== "function"){
        window.onbeforeunload = function(){
          return 'You have made changes to the form which will be lost if you refresh the page. Are you sure?'
        }
      }
    });
  }, 100);

  $(".validate-form").on('submit', validateForm);
  $(document).on("ajax:beforeSend", '.modal-remote-form.validate-form', validateForm);

  function validateForm(e) {
    var $form = $(this).closest("form");
    var valid = $form.valid();
    if(valid){
      window.onbeforeunload = null;
    }
    _.each($form.find("select.selectized"), function(el){
      var $grp = $(el).closest(".mb-3");
      var required = $grp.find(".selectize-input input").attr("required");
      required = required || $grp.hasClass("has-error");
      if(required){
        valid = false;
        $grp.addClass("has-error");
        if($grp.find(".help-block").length == 0){
          $grp.append("<span class='help-block'>This field is required.</span>");
        }else{
          $grp.find(".help-block").insertAfter($grp.find(".selectize-control"))
          $grp.find(".help-block").css("display", "block");
          $grp.find(".help-block").html("This field is required.");
        }
      }
    });
    $(".mb-3.has-error").closest(".panel-collapse").collapse('show');
    if(!valid){
      var $div = $form.find('.mb-3.has-error:first')
      if($div.length > 0){
        $div.find('input,select,textarea').focus();
        $scrollElem = $('html, body');
        if($(e.currentTarget).hasClass('modal-remote-form')) {
          $scrollElem = $(e.currentTarget).find('.modal-remote-form-inner');
        }
        $scrollElem.animate({
            scrollTop: $div.offset().top - 100
        }, 1000);
      }
      e.preventDefault();
      $.unblockUI();
    }
  }
})
