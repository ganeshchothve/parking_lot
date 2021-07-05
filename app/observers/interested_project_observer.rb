class InterestedProjectObserver < Mongoid::Observer
  def after_create interested_project
    interested_project.auto_approve
  end
end
