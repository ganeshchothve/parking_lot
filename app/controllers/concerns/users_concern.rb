module UsersConcern
  extend ActiveSupport::Concern

  def show
    @project_units = @user.project_units.order('created_at DESC').paginate(page: params[:page] || 1, per_page: params[:per_page] || 15)
    @booking_details = @user.booking_details.paginate(page: params[:page] || 1, per_page: params[:per_page] || 15)
    @receipts = @user.receipts.order('created_at DESC').paginate(page: params[:page] || 1, per_page: params[:per_page]|| 15)
    render template: 'admin/users/show'
  end

  def edit
    render layout: false
  end

  def update_password
    render layout: false, template: 'users/update_password'
  end
end