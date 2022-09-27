class Buyer::UsersController < BuyerController
  include UsersConcern

  before_action :set_user, only: %i[show edit update update_password iris_confirm]

  # Show
  # show defined in UsersConcern
  # GET /buyer/users/:id

  # Edit
  # edit defined in UsersConcern
  # GET /buyer/users/:id/edit

  # Update Password
  # update password defined in UsersConcern
  # GET /buyer/users/:id/update_password
  def edit
    render layout: false
  end
  
  def update
    @user.assign_attributes(permitted_attributes([:buyer, @user]))
    respond_to do |format|
      if @user.save
        if permitted_attributes([:buyer, @user]).key?('password')
          bypass_sign_in(@user)
        end
        format.html { redirect_to edit_buyer_user_path(@user), notice: I18n.t("controller.users.notice.profile_updated") }
        format.json { render json: @user }
      else
        format.html { render :edit }
        format.json { render json: { errors: @user.errors.full_messages.uniq }, status: :unprocessable_entity }
      end
    end
  end

  def iris_confirm
    @user.assign_attributes(manager_id: params[:manager_id], iris_confirmation: true, temporarily_blocked: true)
    if @user.save
      redirect_to dashboard_url(@user), notice: I18n.t("global.confirmed")
    else
      redirect_to dashboard_url(@user), notice: I18n.t("controller.users.notice.cannot_confirm")
    end
  end

  def show
    @project_units = @user.project_units.order('created_at DESC').paginate(page: params[:page], per_page: params[:per_page])
    @booking_details = @user.booking_details.paginate(page: params[:page], per_page: params[:per_page])
    @receipts = @user.receipts.order('created_at DESC').paginate(page: params[:page], per_page: params[:per_page])
    @referrals = @user.referrals.order('created_at DESC').paginate(page: params[:page], per_page: params[:per_page])
    respond_to do |format|
      format.html { render template: 'admin/users/show' }
      format.json
    end
  end
  
  private


  def set_user
    @user = current_user
  end
end
