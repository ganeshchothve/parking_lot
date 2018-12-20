class Admin::SmsesController < AdminController
  include SmsConcern
  before_action :set_sms, only: :show #set_sms written in SmsConcern
  before_action :authorize_resource
  around_action :apply_policy_scope, only: :index

  #index and show in SmsConcern

  private


  def apply_policy_scope
    Sms.with_scope(policy_scope([:admin, Sms])) do
      yield
    end
  end

  def authorize_resource
    if params[:action] == 'index'
      authorize [:admin, Sms]
    else
      authorize [:admin, @sms]
    end
  end
end
