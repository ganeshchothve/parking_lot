class Buyer::ReferralsController < BuyerController
  before_action :set_user

  # GET /buyer/referrals
  def index
    authorize [:buyer, Referral]
    @referrals = @user.referrals.paginate(page: params[:page], per_page: 15)
  end

  # GET /buyer/referrals/new
  def new
    @referral = Referral.new(referred_by: current_user)
    authorize [:buyer, @referral]
    render layout: false
  end

  # POST /buyer/referrals
  def create
    referral_user = User.where(email: params.dig(:referral, :email))[0]
    respond_to do |format|
      if referral_user.blank?
        @referral = Referral.new(referred_by: current_user, booking_portal_client: current_client)
        authorize [:buyer, @referral]
        @referral.assign_attributes(permitted_attributes([:buyer, @referral]))
        if @referral.save
          flash[:notice] = "Invitation sent successfully."
          format.json { render json: @referral }
        else
          flash[:error] = "#{@referral.errors.full_messages.join(',')}"
          format.json { render json: { errors: @referral.errors.full_messages }, status: 422 }
        end
      else
        flash[:error] = "#{referral_user.email} is already present."
        format.json { render json: { errors: ["#{referral_user.email} is already present."] }, status: 422 }
      end
      format.html{ redirect_to buyer_referrals_path }
    end
  end

  # GET /buyer/referrals/generate_code
  # This function create a referral code on demand of current user. If code is already created then this action ignore such request.
  def generate_code
    authorize [:buyer, Referral.new]
    @user.generate_referral_code
    respond_to do |format|
      if @user.save
        format.json { render json: @user, status: :created }
        format.js
      else
        format.json { render json: {errors: @user.errors.full_messages.uniq}, status: :unprocessable_entity }
        format.js
      end
    end
  end

  private

  def set_user
    @user = current_user
  end
end