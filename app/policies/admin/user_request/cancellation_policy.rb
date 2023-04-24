class Admin::UserRequest::CancellationPolicy < Admin::UserRequestPolicy
  # def index? def new? def create? def edit? def update? def permitted_attributes from Admin::UserRequestPolicy

  def choose_template_for_print?
    user.role.in?(%w(admin sales sales_admin superadmin gre crm) + User::BUYER_ROLES) && available_templates(record.class.to_s, record).present? && record.status.in?(%w(pending resolved))
  end

  def permitted_attributes(params = {})
    attributes = super
    attributes += [:requestable_id, :requestable_type] if record.new_record? && record.status == 'pending' && %w[admin crm sales superadmin cp sales_admin channel_partner cp_owner].include?(user.role)
    if record.status == "pending"
      attributes += [bank_detail_attributes: BankDetailPolicy.new(user, BankDetail.new).permitted_attributes]
    end
    attributes
  end
end
