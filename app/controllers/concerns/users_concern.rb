module UsersConcern
  extend ActiveSupport::Concern


  def show
    @project_units = @user.project_units.paginate(page: params[:page] || 1, per_page: 15)
    @receipts = @user.receipts.where("$or": [{ status: 'pending', payment_mode: { '$ne' => 'online' } }, { status: { '$ne' => 'pending' } }]).paginate(page: params[:page] || 1, per_page: 15)
    render template: 'admin/users/show'
  end

  def edit
    render layout: false
  end

  def update_password
    render layout: false, template: 'users/update_password'
  end
end