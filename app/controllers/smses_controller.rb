class SmsesController < BuyerController
  include SmsConcern
  before_action :set_sms, only: :show #set_sms written in SmsConcern
  around_action :apply_policy_scope, only: :index

  def index
    @smses = Sms.build_criteria params
    authorize([:buyer, @smses])
    @smses = @smses.order(created_at: :desc).paginate(page: params[:page] || 1, per_page: 15)
  end

  def show
    authorize([:buyer, @sms])
  end

  private


  def apply_policy_scope
    Sms.with_scope(policy_scope([:buyer, Sms])) do
      yield
    end
  end
end
