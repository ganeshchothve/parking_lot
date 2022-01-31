class ProjectPolicy < ApplicationPolicy
  def switch_project?
    ( !user.role.in?(User::ALL_PROJECT_ACCESS + %w(channel_partner)) || user.buyer? ) && user.project_ids.count > 0
  end
end
