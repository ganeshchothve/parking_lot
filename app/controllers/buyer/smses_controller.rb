class Buyer::SmsesController < BuyerController
  include SmsConcern
  before_action :set_sms, only: :show #set_sms written in SmsConcern
  before_action :authorize_resource
  around_action :apply_policy_scope, only: :index
  around_action :user_time_zone, if: :current_user
  # index defined in SmsConcern
  # GET /buyer/smses

  # show defined in SmsConcern
  # GET /buyer/smses/:id

  private


  def apply_policy_scope
    Sms.with_scope(policy_scope([:buyer, Sms])) do
      yield
    end
  end

  def authorize_resource
    if params[:action] == 'index'
      authorize [:buyer, Sms]
    else
      authorize [:buyer, @sms]
    end
  end
end
