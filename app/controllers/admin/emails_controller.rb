class Admin::EmailsController < AdminController
  include EmailConcern
  before_action :set_email, only: %w[show resend_email]#set_email written in EmailConcern
  before_action :authorize_resource
  around_action :apply_policy_scope, only: :index

  # index defined in EmailConcern
  # GET /admin/emails

  # show defined in EmailConcern
  # GET /admin/emails/:id

  def monthly_count
    params.merge!(booking_portal_client_id: current_client.try(:id))
    if params[:fltrs] && params[:fltrs][:sent_on]
      @monthly_count = Email.monthly_count(params[:fltrs][:sent_on], params)
    else
      @monthly_count = Email.monthly_count(nil, params)
    end
  end

  private

  def apply_policy_scope
    custom_scope = Email.where(Email.user_based_scope(current_user, params))
    Email.with_scope(policy_scope(custom_scope)) do
      yield
    end
  end

  def authorize_resource
    if params[:action].in?(%w(index monthly_count))
      authorize [:admin, Email]
    else
      authorize [:admin, @email]
    end
  end
end
