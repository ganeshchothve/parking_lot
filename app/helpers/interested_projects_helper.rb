module InterestedProjectsHelper
  def available_statuses interested_project
    statuses = interested_project.aasm.events(permitted: true).collect{|x| x.name.to_s}
  end
end
