# TODO: replace all messages & flash messages
class DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project_unit, only: [:filter_data,:project_unit, :update_project_unit, :hold_project_unit, :checkout, :payment]
  layout :set_layout

  def index
    authorize :dashboard, :index?
    @project_units = current_user.project_units
  end

  def get_towers
    scope=ProjectUnit.all    
    scope = scope.where(:bedrooms=>params[:configuration]) if params[:configuration]  
    if params[:base_price]
      budget= params[:base_price].split("-")
      scope=scope.where(base_price: (budget.first..budget.last))
    end
    towers=scope.order_by(:project_tower_id => "asc").only([:project_tower_id, :project_tower_name]).uniq! {|e| e[:project_tower_id] }.to_json(:except => :_id)
    render json: JSON(towers)
  end

  def get_units
    projectunit=ProjectUnit.where(:project_tower_id=>params[:project_tower_id]).order_by(:floor => "desc").to_json
    render json: JSON(projectunit)
  end

  def get_unit_details
    render json: JSON(ProjectUnit.find(params[:unit_id]).to_json)
  end

  def filter_data
    obj=params[:filter]
    obj.keys.each do |key|
      @project_unit.send("#{key}=", obj[key]) if project_tower.respond_to?("#{key}")
    end
    @project_unit.save    
    configuration=@project_unit.unit_configuration.to_json(:except => :_id)
    render json: JSON(configuration)
  end

  def project_units
    authorize :dashboard, :project_units?
    @project_units = current_user.project_units
  end

  def project_units_new
    authorize :dashboard, :project_units?
    @project_units = current_user.project_units
  end

  def project_unit
    authorize @project_unit
  end

  def checkout
    if params[:project_unit_id].present?
      authorize @project_unit
    else
      authorize(Receipt.new(user: current_user), :new?)
    end
  end

  def payment
    @receipt = Receipt.new(creator: current_user, user: current_user, receipt_id: SecureRandom.hex, payment_mode: 'online', total_amount: ProjectUnit.blocking_amount, payment_type: 'blocking')

    if params[:project_unit_id]
      authorize @project_unit
      if(current_user.total_unattached_balance >= ProjectUnit.blocking_amount)
        @receipt = current_user.unattached_blocking_receipt
      end

      @receipt.project_unit = @project_unit
    else
      authorize(Receipt.new(user: current_user), :new?)
    end
    if @receipt.save
      if @receipt.status == "pending" # if we are just tagging an already successful receipt, we dont need to send the user to payment gateway
        if Rails.env.development?
          encrypted_data = @receipt.build_for_hdfc
          redirect_to "https://test.ccavenue.com/transaction/transaction.do?command=initiateTransaction&encRequest=#{encrypted_data}&access_code=#{PAYMENT_PROFILE[:CCAVENUE][:accesscode]}"
          #redirect_to "/payment/hdfc/process_payment?receipt_id=#{@receipt.id}"
        end
      elsif ['clearance_pending', "success"].include?(@receipt.status)
        redirect_to dashboard_path
      end
    else
      redirect_to dashboard_checkout_path(project_unit_id: @project_unit.id)
    end
  end

  def update_project_unit
    authorize @project_unit
    respond_to do |format|
      if @project_unit.update_attributes(permitted_attributes(@project_unit))
        format.html { redirect_to dashboard_project_units_path }
        format.json { render json: {project_unit: @project_unit}, status: 200 }
      else
        flash[:notice] = 'Could not update the project unit. Please retry'
        format.html { redirect_to request.referer.present? ? request.referer : dashboard_project_units_path }
        format.json { render json: {errors: @project_unit.errors.full_messages.uniq}, status: 422 }
      end
    end
  end

  def hold_project_unit
    authorize @project_unit
    @project_unit.attributes = permitted_attributes(@project_unit)
    # TODO: get a lock on this model. Nobody can modify it.
    respond_to do |format|
      # TODO: handle this API method for other status updates. Currently its assuming its a hold request
      case hold_on_third_party_inventory
      when 'hold'
        format.html { redirect_to dashboard_checkout_path(project_unit_id: @project_unit.id) }
      when 'not_available'
        flash[:notice] = 'The unit is not available'
        format.html { redirect_to dashboard_project_units_path }
      when 'price_change'
        flash[:notice] = 'The Unit price has changed'
        format.html { redirect_to dashboard_checkout_path(project_unit_id: @project_unit.id) }
      when 'error'
        flash[:notice] = 'We cannot process your request at this time. Please retry'
        format.html { redirect_to dashboard_project_units_path }
      end
    end
  end

  private
  def set_project_unit
    @project_unit = ProjectUnit.find(params[:project_unit_id])  if params[:project_unit_id].present?
  end

  def hold_on_third_party_inventory
    third_party_inventory_response, third_party_inventory_response_code = ThirdPartyInventory.hold_on_third_party_inventory(@project_unit)
    # TODO: if third_party_inventory timesouts, need to revert the hold on the project unit in our db
    if third_party_inventory_response_code == 200
      ThirdPartyInventory.map_third_party_inventory(@project_unit, third_party_inventory_response)
      # once we have the updated model, just set the code for the controller method and update the project unit
      if @project_unit.base_price_changed?
        @project_unit.user = current_user
        code = 'price_change'
      elsif @project_unit.status == 'hold'
        @project_unit.user = current_user
        code = 'hold'
      elsif @project_unit.status != 'hold'
        code = 'not_available'
      end
      unless @project_unit.save
        code = 'error'
      end
    else
      code = 'error'
    end
    code
  end
end
