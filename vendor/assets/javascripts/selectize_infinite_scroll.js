Selectize.define('infinite_scroll', function(options) {
  var self = this
    , page = 1;
    option_size = 0;

  self.infinitescroll = {
    onScroll: function() {
      page++
      var scrollBottom = self.$dropdown_content[0].scrollHeight - (self.$dropdown_content.scrollTop() + self.$dropdown_content.height())
      if(scrollBottom < 300){
        var query = JSON.stringify({
          search: self.lastValue,
          page: page
        })

        self.$dropdown_content.off('scroll')
        self.onSearchChange(query)
      }
    }
  };

  self.onFocus = (function() {
    var original = self.onFocus;

    return function() {
      var query = JSON.stringify({
        search: self.lastValue,
        page: page
      })

      original.apply(self, arguments);
      self.onSearchChange(query)
    };
  })();

  self.onKeyUp = function(e) {
    var self = this;

    if (self.isLocked) return e && e.preventDefault();
    var value = self.$control_input.val() || '';

    if (self.lastValue !== value) {
      var query = JSON.stringify({
        search: value,
        page: page = 1
      });

      self.lastValue = value;
      self.onSearchChange(query);
      self.refreshOptions();
      if($(e.target).closest('.clear-options').length >= 1)
        self.clearOptions();

      self.trigger('type', value);
    }
  };

  self.on('load',function(){
    if(option_size < _.size(self.options)){
      page++
      option_size = _.size(self.options)
      self.$dropdown_content.on('scroll', self.infinitescroll.onScroll);
    }
  });

});
