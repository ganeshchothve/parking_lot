# consumes workflow api for leads from sell.do
class Api::SellDo::LeadsController < Api::SellDoController
  before_action :set_user

  def lead_created
    respond_to do |format|
      if @user.save
        format.json { render json: @user, status: :created }
      else
        format.json { render json: {errors: @user.errors.full_messages.uniq}, status: :unprocessable_entity }
      end
    end
  end

  def pushed_to_sales
    @user.confirm # also confirm the user in case of a push to sales event
    respond_to do |format|
      if @user.save
        format.json { render json: @user, status: :created }
      else
        format.json { render json: {errors: @user.errors.full_messages.uniq} }
      end
    end
  end

  def set_user
    @user = User.where(lead_id: params[:lead_id].to_s).first
    if @user.blank?
      @user = User.new(booking_portal_client_id: current_client.id, email: params[:lead][:email], phone: params[:lead][:phone], first_name: params[:lead][:first_name], last_name: params[:lead][:last_name], lead_id: params[:lead_id])
    end
  end
end
