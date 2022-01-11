class Buyer::EmailsController < BuyerController
  include EmailConcern
  before_action :set_email, only: :show #set_email written in EmailConcern
  before_action :authorize_resource
  around_action :apply_policy_scope, only: :index
  # index defined in EmailConcern
  # GET /buyer/emails

  # show defined in EmailConcern
  # GET /buyer/emails/:id

  private


  def apply_policy_scope
    Email.with_scope(policy_scope([:buyer, Email])) do
      yield
    end
  end

  def authorize_resource
    if params[:action] == 'index'
      authorize [:buyer, Email]
    else
      authorize [:buyer, @email]
    end
  end
end
