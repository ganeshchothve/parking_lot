# consumes workflow api for leads from sell.do
class Api::SellDo::LeadsController < Api::SellDoController
  before_action :set_user

  def lead_created
    respond_to do |format|
      if @user.save
        format.json { render json: @user }
      else
        format.json { render json: {errors: @user.errors.full_messages.uniq} }
      end
    end
  end

  def pushed_to_sales
    @user.confirm # also confirm the user in case of a push to sales event
    respond_to do |format|
      if @user.save
        format.json { render json: @user }
      else
        format.json { render json: {errors: @user.errors.full_messages.uniq} }
      end
    end
  end

  def set_user
    if params[:data].present? && params[:data][:lead_id].present?
      @user = User.where(lead_id: params[:data][:lead_id].to_s).first
      if @user.blank?
        @user = User.new(booking_portal_client_id: current_client.id, email: params[:data][:lead][:email], phone: params[:data][:lead][:phone], first_name: params[:data][:lead][:first_name], last_name: params[:data][:lead][:last_name], lead_id: params[:data][:lead_id])
        @user.first_name = "Customer" if @user.first_name.blank?
      end
    else
      respond_to do |format|
        format.json { render json: {} and return }
      end
    end
  end
end
