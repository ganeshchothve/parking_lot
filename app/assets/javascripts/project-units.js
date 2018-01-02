var Inventory = (function(){
  var project_unit_id;
  var _init = function(project_unit_id){
    this.project_unit_id = project_unit_id;
    _hold_on_portal().then(function(){
      _hold_on_sfdc();
    }, function(){
      // Major issue -> report to us via email
      // notify user about error and ask for retry
    });
  }
  var _hold_on_portal = function(){
    $.ajax({
      url: '',
      dataType: 'json',
      type: 'POST'
    });
  }
  var _hold_on_sfdc = function(){
    $.ajax({
      url: '',
      dataType: 'json',
      type: 'POST'
    }).then(function(){
      // redirect to final page to show to choose payment gateway method
    }, function(){
      // SFDC issue -> report to us via email & to their SFDC Team (if required)
      // notify user about error and ask for retry
    });
  }
  return {
    init: _init,
    hold: _hold_on_portal
  };
})();
