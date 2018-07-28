$(document).ready(function(){
  if(window.history && typeof window.history.pushState === "function"){
    var href = window.location.href;
    if(href.indexOf("remote-state=") != -1){
      var param = Amura.getParamFromURL(window.location.href, "remote-state");
      modal_remote_form_link_click_handler(param);
    }
  }
});

$(document).on("click", '.modal-remote-form-link', function(e){
  e.preventDefault();
  modal_remote_form_link_click_handler($(this).attr("href"));
});

var handle_remote_pushstate = function(){
  if(window.history && typeof window.history.pushState === "function"){
    $("#modal-remote-form-inner").off("hide.bs.modal", handle_remote_pushstate);
    var href = Amura.removeParamFromURL(window.location.href, "remote-state");
    window.history.pushState(null, null, href);
  }
}

var modal_remote_form_link_click_handler = function(remote_href){
  $.blockUI();
  if(!_.isEmpty(remote_href) && remote_href != "javascript:;" && remote_href != "javascript:void(0);"){
    if(window.history && typeof window.history.pushState === "function"){
      var href = Amura.removeParamFromURL(window.location.href, "remote-state");
      if(href.indexOf("?") == -1){
        href += "?";
      }else{
        href += "&";
      }
      href += "remote-state=" + remote_href;
      window.history.pushState(null, null, href);
    }
    $.ajax({
      url: remote_href,
      type: "GET",
      dataType: "html",
      success: function(one){
        if($("#modal-remote-form-container").length == 0){
          $('body').append('<div id="modal-remote-form-container"></div>');
        }
        $("#modal-remote-form-container").html(one);
        $("#modal-remote-form-inner").modal({
          backdrop: 'static',
          show: true,
          keyboard: false,
          focus: true
        });
        $("#modal-remote-form-container [data-toggle='tooltip']").tooltip();
        if(window.history && typeof window.history.pushState === "function"){
          $("#modal-remote-form-inner").on("hide.bs.modal", handle_remote_pushstate);
        }
      },
      error: function(){
        Amura.global_error_handler("Error while fetching modal remote form");
      },
      complete: function(){
        $.unblockUI();
      }
    });
  }
}
$(document).on("ajax:success", '.modal-remote-form', function(event){
  var detail = event.detail;
  var data = detail[0], status = detail[1], xhr = detail[2];

  var message = "";
  var resource = $(event.currentTarget).attr("data-resource-type");
  if(resource){
    message += resource + " ";
  }
  if(xhr.status == 201){
    message += "created successfully";
  }else{
    message += "updated successfully";
  }
  Amura.global_success_handler(message);
  var dismiss = $("#modal-remote-form").data("dismiss-modal");
  if(typeof dismiss != "undefined" && dimiss == false){
  }else{
    $("#modal-remote-form-inner").modal("hide");
    setTimeout(function(){
      if($("#modal-remote-form-container").length == 0){
        $('body').append('<div id="modal-remote-form-container"></div>');
      }
      $("#modal-remote-form-container").html("");
    }, 2500);
    // handle location on JSON response
    if(xhr.getResponseHeader('location')){
      window.location = xhr.getResponseHeader('location')
    }else{
      window.location = window.location;
    }
  }
});
$(document).on("ajax:error", '.modal-remote-form', function(event){
  var detail = event.detail;
  var data = detail[0], status = detail[1], xhr = detail[2];
  if( data ){
    if ( data.errors ){
      Amura.global_error_handler(data.errors);
    }else{
      Amura.global_error_handler(errors);
    }
  }else{
    Amura.global_error_handler("We could not update your record.");
  }
});
