class Admin::EmailsController < AdminController
  include EmailConcern
  before_action :set_email, only: :show #set_email written in EmailConcern
  before_action :authorize_resource
  around_action :apply_policy_scope, only: :index
  around_action :user_time_zone, if: :current_user

  # index defined in EmailConcern
  # GET /admin/emails

  # show defined in EmailConcern
  # GET /admin/emails/:id

  def monthly_count
    if params[:fltrs] && params[:fltrs][:sent_on]
      @monthly_count = Email.monthly_count(params[:fltrs][:sent_on])
    else
      @monthly_count = Email.monthly_count
    end
  end

  private

  def apply_policy_scope
    Email.with_scope(policy_scope([:admin, Email])) do
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
