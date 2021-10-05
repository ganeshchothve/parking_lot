class Admin::VideoPolicy < VideoPolicy
  def create?
    "Admin::#{record.videoable_type}Policy".constantize.new(user, record.videoable).video_create?
  end

  def update?
    create?
  end

  def destroy?
    "Admin::#{record.videoable_type}Policy".constantize.new(user, record.videoable).video_update?
  end
end
