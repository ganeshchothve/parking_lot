class Buyer::SmsesController < BuyerController
  include SmsConcern
  before_action :set_sms, only: :show #set_sms written in SmsConcern
  before_action :authorize_resource
  around_action :apply_policy_scope, only: :index

  #index and show in SmsConcern

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
