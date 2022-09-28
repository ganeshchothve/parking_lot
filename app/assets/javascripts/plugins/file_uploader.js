(function($){
  var template = function(record, options){
    var file_name = record.name;
    if(_.isEmpty(file_name)){
      file_name = _.last(record.url.split("/"));
    }

    var content_type_class = FileIcon.mime2class(record.content_type);
    if(_.isEmpty(content_type_class) && !_.isEmpty(record.type)){
      content_type_class = FileIcon.mime2class(record.type);
    }

    var progress_bar = '\ <div class="progress progress-height">\
                            <div class="progress-bar" title = "'+ file_name + '" style="width: 0%;"></div>\
                            </div>\
                          </div>'

    return '<div id="upload-progress-' + options.random_id + '" class="asset" title="' + file_name.replace(/ /g, "_") + '">\
              <div class="asset-inner ' + (options.progress_bar ? 'asset-blur' : '') +'">\
                <div class="asset-icon ' + content_type_class + '"></div>\
              </div>\
            <div class="upload-completed-message hidden">Upload completed</div>\
            <div class="asset-actions ">\
              <a href="' + record.url + '" target="_blank" title="Download" class="asset-download" download=""><i class="fa fa-download"></i></a>\
              <a href="" title="Delete" class="asset-delete"><i class="fa fa-times"></i></a>\
            </div>\
            <div class="asset-name" title="' + file_name + '">' + file_name + '</div>\
          '+ (options.progress_bar ? progress_bar : '')+ '</div>'
  };
  $.fn.fileUploader = function(options){
    var label = this.data("label") || '';
    var url = this.data("url");
    this.closest(".fileinput-button").prepend('<span>' + label + '</span>');
    this.fileupload({
      url: url,
      dataType: 'json',
      add: function (e, data) {
        $.blockUI();
        var errors = [];
        var self = this;
        var extensions = $(this).data("extensions");
        _.each(data.files, function(file) {
          var file_arr = file.name.split('.');
          var tmp = file_arr.slice(Math.max(file_arr.length - 2, 1)).join(".");
          if( !_.isUndefined(extensions) && !_.isEmpty(extensions) ) {
            if(!_.includes( extensions.split(","), tmp)){
              errors.push("'" + tmp + "' is not supported file format" );
            }
          }
          if(file.size > 100000000) {
            errors.push(file.name + "'s size is greater than 100 mb");
          }
          if( _.isEmpty( errors ) ) {
            data.random_id = _.random(99999999999)
            var doc_html = template(file, {progress_bar: true, random_id: data.random_id})
            var target = $(".files-container");
            if(!_.isEmpty($(self).data("target"))){
              target = $($(self).data("target"));
            }
            $(target).append(doc_html);
          }

        });

        if( _.isEmpty( errors ) ) {
          data.formData = $(this).data("form-data");
          data.submit();
        } else { // display pop up
          // TODO move this to a bootstrap alert
          Amura.global_error_handler(errors)
        }
      },
      done: function (e, data) {
        if(!_.isEmpty(data.result)){
          var file_name = _.last(data.result.url.split("/"));
          var $container = $("#upload-progress-" + data.random_id);
          $container.find(".progress").remove();
          $container.find('.upload-completed-message').removeClass('hidden');
          $container.find(".asset-download").attr("href", data.result.url);
          $container.find(".asset-delete").attr("href", Amura.removeParamFromURL(url, 'locale') + '/' + data.result.id);
          FileIcon.init($container.find(".asset-delete"), $container.find(".asset-icon"));
          setTimeout(function(){
            $container.find('.upload-completed-message').addClass('hidden');
            $container.find(".asset-inner").removeClass("asset-blur");
          }, 1500);
          $.unblockUI();
        }
      },
      progress: function (e, data) {
        var file_name = data.files[0].name
        var progress = parseInt(data.loaded / data.total * 100);
        $("#upload-progress-" + data.random_id + " .progress-bar").css(
            'width',
            progress + '%'
        );
      },
      error: function(e, textStatus, errorThrown){
        if( typeof e.responseJSON == 'object'){
          Amura.global_error_handler(e.responseJSON.errors);
        }
        $.unblockUI();
      }
    });
    var self= this;
    if(!_.isEmpty(options) && !_.isEmpty(options.records)){
      _.each(options.records, function(record){
        var html = template(record, {});
        var target = $(".files-container");
        if(!_.isEmpty($(self).data("target"))){
          target = $($(self).data("target"));
        }
        target.append(html);
      });
    }
  };
})(jQuery);
