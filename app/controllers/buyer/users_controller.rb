class Buyer::UsersController < BuyerController

  include UsersConcern

  before_action :set_user, only: %i[show edit update update_password]

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

  private

  def set_user
    @user = current_user
  end

end