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

  def select_projects
    @projects = current_client.projects
  end

  def select_project
    if params[:project_id].present? && current_user.buyer?
      @lead = Lead.find_or_initialize_by(booking_portal_client_id: current_client, project_id: params[:project_id], user_id: current_user.id)
      if @lead.new_record?
        @lead.assign_attributes(first_name: current_user.first_name, last_name: current_user.last_name, email: current_user.email, phone: current_user.phone)
        @lead.save
      end
      redirect_to resource_wise_redirection(params[:redirect_to])
    end
  end
  
  private

  def resource_wise_redirection(redirect_to = 'receipt')
    case redirect_to
    when 'receipt'
      buyer_receipts_path('remote-state': new_buyer_receipt_path(lead_id: @lead.id))
    when 'kyc'
      buyer_user_kycs_path('remote-state': new_buyer_user_kyc_path(lead_id: @lead.id))
    else
      home_path(current_user)
    end
  end

  def set_user
    @user = current_user
  end
end
