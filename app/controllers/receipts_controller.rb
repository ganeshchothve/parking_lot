class ReceiptsController < ApplicationController
  before_action :authenticate_user!
  layout 'dashboard'

  def index
    @receipts = current_user.receipts # TODO: need to paginate here
  end

  def show
    @receipt = Receipt.find(params[:id])
    authorize @receipt
  end

  def new
    if params[:project_unit_id].blank?
      redirect_to(receipts_path)
      return
    end
    project_unit = ProjectUnit.find(params[:project_unit_id])
    @receipt = Receipt.new(project_unit_id: project_unit.id, user_id: current_user.id, total_amount: project_unit.pending_balance, status: 'booking')
    authorize @receipt
  end

  def create
    @receipt = Receipt.new(permitted_attributes(Receipt.new))
    @receipt.user = current_user
    @receipt.receipt_id = SecureRandom.hex
    @receipt.payment_type = 'booking'
    authorize @receipt
    respond_to do |format|
      if @receipt.save
        format.html {
          if Rails.env.development?
            redirect_to "/payment/hdfc/process_payment?receipt_id=#{@receipt.id}"
          else
            redirect_to root_path # TODO: redirect the user to the payment gateway link
          end
        }
      else
        format.html { render 'new' }
      end
    end
  end
end
