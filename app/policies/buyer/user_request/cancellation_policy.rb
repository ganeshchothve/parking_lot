class Buyer::UserRequest::CancellationPolicy < Buyer::UserRequestPolicy
  # def index? def new? def create? def edit? def update? def permitted_attributes from Buyer::UserRequestPolicy
  
  def choose_template_for_print?
    user.role.in?(User::BUYER_ROLES) && available_templates(record.class.to_s, record).present? && record.status.in?(%w(pending resolved))
  end
end
