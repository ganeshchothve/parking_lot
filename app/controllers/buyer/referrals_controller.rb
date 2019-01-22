class Buyer::ReferralsController < BuyerController

  before_action :authorize_resource

  def index
    @referrals = current_user.referrals.paginate(page: params[:page], per_page: 15)
  end

  def new

  end

  def create
  end

  private

  def authorize_resource
    authorize [:buyer, :referral], "#{action_name}?"
  end
end