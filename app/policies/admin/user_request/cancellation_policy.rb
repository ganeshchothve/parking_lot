class Admin::UserRequest::CancellationPolicy < Admin::UserRequestPolicy
  # def index? def new? def create? def edit? def update? def permitted_attributes from Admin::UserRequestPolicy
  def permitted_attributes(params = {})
    attributes = super
    attributes += [:requestable_id, :requestable_type] if record.new_record? && record.status == 'pending' && %w[admin crm sales superadmin cp sales_admin channel_partner cp_owner].include?(user.role)
    attributes
  end
end
