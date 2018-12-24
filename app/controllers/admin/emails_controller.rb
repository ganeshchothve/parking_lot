class Admin::EmailsController < AdminController
  include EmailConcern
  before_action :set_email, only: :show #set_email written in EmailConcern
  before_action :authorize_resource
  around_action :apply_policy_scope, only: :index

  # index defined in EmailConcern
  # GET /admin/emails

  # show defined in EmailConcern
  # GET /admin/emails/:id

  private


  def apply_policy_scope
    Email.with_scope(policy_scope([:admin, Email])) do
      yield
    end
  end

  def authorize_resource
    if params[:action] == 'index'
      authorize [:admin, Email]
    else
      authorize [:admin, @email]
    end
  end
end
