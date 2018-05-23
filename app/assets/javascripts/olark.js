var ChatHelp = (function(){
  var init = function(){
    olark('api.visitor.getDetails', function(details){
      if(_.isEmpty(details.emailAddress)){
        olark('api.visitor.updateEmailAddress',{
          emailAddress: App.current_user.email
        });
      }
      if(_.isEmpty(details.fullName)){
        olark('api.visitor.updateFullName',{
          fullName: App.current_user.name
        });
      }
      if(_.isEmpty(details.phoneNumber)){
        olark('api.visitor.updatePhoneNumber', {
          phoneNumber: App.current_user.phone
        });
      }
      if(_.isEmpty(details.customFields.lead_id) && !_.isEmpty(App.current_user.lead_id)){
        olark('api.visitor.updateCustomFields', {
          sell_do_lead_id: App.current_user.lead_id
        });
      }
      snippet = App.current_user.name;
      if(App.current_user.lead_id){
        snippet += " (#" + App.current_user.lead_id + ") ";
      }
      snippet += "is a " + App.current_user.role;
      olark('api.chat.updateVisitorNickname', {
        snippet: snippet
      })
    });
  }

  var message = function(message){
    var olark_interval = setInterval(function(){
      if(typeof olark === "function"){
        olark('api.chat.sendNotificationToOperator', {
            body: message
        });
        clearInterval(olark_interval)
      }
    }, 100)
  }

  return {
    init: init,
    message: message
  };
})();
$(document).ready(function(){
  ChatHelp.init();
});
