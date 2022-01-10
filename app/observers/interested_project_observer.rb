class InterestedProjectObserver < Mongoid::Observer
  include ApplicationHelper

  def after_create interested_project
    interested_project.auto_approve

    if current_client.external_api_integration?
      if Rails.env.staging? || Rails.env.production?
        InterestedProjectObserverWorker.perform_async(interested_project.id.to_s)
      else
        InterestedProjectObserverWorker.new.perform(interested_project.id.to_s)
      end
    end
  end
end
