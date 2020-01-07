App.room = App.cable.subscriptions.create "WebNotificationsChannel",
  received: (data) ->
    $('#messages').append data['message']

App.progress_bar = App.cable.subscriptions.create "ProgressBarChannel",
  received: (data) ->
    $('#progress').css('width', data['progress']+'%').attr('aria-valuenow', data['progress']).html(data['progress'] + "%");
    if data['progress'] == "100"
      $(".done").removeClass("d-none")
      $(".progress-div-text").html("<h2>Finished!</h2><h3>"+ data['success'] + " uploaded out of " + data['total'] + "</h3>")
      App.progress_bar.unsubscribe();
      App.room.unsubscribe();