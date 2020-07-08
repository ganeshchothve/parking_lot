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

  def update
    @user.assign_attributes(permitted_attributes([:buyer, @user]))
    respond_to do |format|
      if @user.save
        if permitted_attributes([:buyer, @user]).key?('password')
          bypass_sign_in(@user)
        end
        format.html { redirect_to edit_buyer_user_path(@user), notice: 'User Profile updated successfully.' }
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
      redirect_to dashboard_url(@user), notice: 'Confirmation successfull.'
    else
      redirect_to dashboard_url(@user), notice: 'Cannot confirm with this link. Please contact administrator'
    end
  end

  private


  def set_user
    @user = current_user
  end
end
