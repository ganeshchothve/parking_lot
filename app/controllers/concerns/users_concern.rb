module UsersConcern
  extend ActiveSupport::Concern

  def show
    @project_units = @user.project_units.order('created_at DESC').paginate(page: params[:page], per_page: params[:per_page])
    @booking_details = @user.booking_details.paginate(page: params[:page], per_page: params[:per_page])
    @receipts = @user.receipts.order('created_at DESC').paginate(page: params[:page], per_page: params[:per_page])
    @referrals = @user.referrals.order('created_at DESC').paginate(page: params[:page], per_page: params[:per_page])
    respond_to do |format|
      format.html { render template: 'admin/users/show' }
      format.json { render json: { user: @user.as_json } }
    end
  end

  def edit
    render layout: false
  end

  def update_password
    render layout: false, template: 'users/update_password'
  end
end
