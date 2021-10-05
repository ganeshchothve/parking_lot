class VideoPolicy < ApplicationPolicy

  def show?
    true
  end

  def index?
    false
  end

  def permitted_attributes params={}
    attributes = [:thumbnail, :videoable_id, :videoable_type, :description, :embedded_video ]

    if record.videoable_type.present? && "Admin::#{record.videoable_type}Policy".constantize.new(user, record.videoable).update?
      attributes  += [:id]
    end
    attributes
  end
end
