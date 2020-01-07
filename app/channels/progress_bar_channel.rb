class ProgressBarChannel < ApplicationCable::Channel
  def subscribed
    stream_from "progress_bar_channel"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
