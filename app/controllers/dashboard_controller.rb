# TODO: replace all messages & flash messages
class DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project_unit, only: [:project_unit, :update_project_unit, :update_co_applicants, :hold_project_unit, :checkout, :payment, :payment_breakup, :make_remaining_payment]
  layout :set_layout

  def index
    authorize :dashboard, :index?
    @project_units = current_user.project_units
  end

  def get_towers
    parameters = {fltrs: { data_attributes: {bedrooms: params[:bedrooms], agreement_price: params[:agreement_price]}} }
    scope = ProjectUnit.build_criteria(parameters)
    towers = scope.uniq{|e| e.project_tower_id }.collect{|x| {project_tower_id: x.project_tower_id, project_tower_name:x.project_tower_name}}
    render json: towers
  end

  def get_units
    parameters = {fltrs: { project_tower_id: params[:project_tower_id] } }
    render json: ProjectUnit.build_criteria(parameters).collect{|x| x.ui_json}
  end

  def get_unit_details
    render json: ProjectUnit.find(params[:unit_id]).ui_json
  end

  def razorpay_payment
    @receipt = Receipt.where(:receipt_id => params[:receipt_id]).first
    if @receipt.present? && @receipt.status == "pending"
      ApplicationLog.log("sent_to_payment_gateway", {
        receipt_id: @receipt.id,
        unit_id: @receipt.project_unit_id,
        user_id: @receipt.user_id
      }, RequestStore.store[:logging])
      SelldoLeadUpdater.perform_async(@receipt.user_id.to_s, "sent_to_payment_gateway")
    else
      redirect_to home_path(current_user)
    end
  end

  def payment_breakup
  end

  def make_remaining_payment
  end

  def faq
  end

  def rera
  end

  def tds_process
  end

  def terms_and_conditions
  end

  def receipt_mail
    @receipt = Receipt.find(params[:id])
    @user = @receipt.user
    @project_unit = @receipt.project_unit
    @cp = @user.channel_partner
    respond_to do |format|
      format.html
      format.pdf do
        render  pdf: "Embassy Receipt",
        title: 'Embassy Receipt',
        save_to_file: Rails.root.join('tmp', "receipt.pdf")
        # ReceiptMailer.send_receipt(@receipt.id).deliver_now
      end
    end
  end

  def send_allotment
    @receipt = Receipt.find(params[:id])
    @user = @receipt.user
    @project_unit = @receipt.project_unit
    @cp = @user.channel_partner
    respond_to do |format|
      format.html
      format.pdf do
        render  pdf: "Embassy Allotment",
        title: 'Embassy Allotment',
        save_to_file: Rails.root.join('tmp', "allotment.pdf")
      end
    end
  end

  def eoi_receipt
    @user = User.find(params[:id])
    respond_to do |format|
      format.html
      format.pdf do
        render  pdf: "EOI Receipt",
        title: 'EOI Receipt'
      end
    end
  end

  def receipt
    @receipt = Receipt.find(params[:format])
  end

  def receipt_print
    @receipt = Receipt.find(params[:id])
    @user = @receipt.user
    @project_unit = @receipt.project_unit
    @cp = @user.channel_partner
    respond_to do |format|
      format.html
      format.pdf do
        render  pdf: "Embassy Receipt",
        title: 'Embassy Receipt',
        save_to_file: Rails.root.join('tmp', "receipt_mail.pdf")
        # ReceiptMailer.receipt_email(@receipt.id).deliver_now
      end
    end
  end

  def foyr_unit_status
    project_unit = ProjectUnit.where(sfdc_id: params[:project_unit_id]).first
    respond_to do |format|
      format.json do
        if project_unit.present?
          status = project_unit.user_based_status(current_user) == "available" ? "Available" : "Booked"
          render json: {
            price: project_unit.agreement_price,
            apartment_ID: project_unit.sfdc_id,
            status: status
          }
        else
          render json: {}, status: 404
        end
      end
    end
  end

  def project_units_3d
    authorize :dashboard, :project_units?
  end

  def project_units
    authorize :dashboard, :project_units?
    if params[:stage] == "apartment_selector"
      @configurations = ProjectUnit.all.collect{|x| {bedrooms: x.bedrooms, agreement_price: x.agreement_price.to_i}}.sort{|x, y| x[:agreement_price] <=> y[:agreement_price]}.uniq{|x| x[:bedrooms]}
    elsif params[:stage] == "choose_tower"
      bedroom = params[:configuration].split(",")[0]
      budget = params[:configuration].split(",")[1]
      @parameters =  {fltrs: { data_attributes: {bedrooms: bedroom != "NA" ? bedroom : ""}, agreement_price: budget != "NA" ? budget : ""}}
      project_tower_ids = ProjectUnit.build_criteria(@parameters).in(status: ProjectUnit.user_based_available_statuses(current_user)).distinct(:project_tower_id)
      @towers = ProjectTower.in(id: project_tower_ids).collect do |x|
        hash = {project_tower_id: x.id, project_tower_name:x.name}
        hash[:total_units] = ProjectUnit.where(project_tower_id: x.id).count
        hash[:total_units_available] = ProjectUnit.build_criteria(@parameters).where(project_tower_id: x.id).in(status: ProjectUnit.user_based_available_statuses(current_user)).count
        hash
      end
      if @towers.blank?
        alternative_params = {}
        @alternative_count = 0
        if bedroom != "NA"
          alternative_params =  {fltrs: { data_attributes: {bedrooms: bedroom != "NA" ? bedroom : ""}}}
        elsif agreement_price != "NA"
          alternative_params =  {fltrs: { data_attributes: {agreement_price: budget != "NA" ? budget : ""}}}
        end
        @alternative_count = ProjectUnit.build_criteria(@parameters).in(status: ProjectUnit.user_based_available_statuses(current_user)).count if alternative_params.present?
      end
      SelldoLeadUpdater.perform_async(current_user.id.to_s, "unit_browsing")
    elsif params[:stage] == "select_apartment"
      @tower = ProjectTower.find(id: params[:project_tower_id])
      @configurations = ProjectUnit.all.collect{|x| {bedrooms: x.bedrooms, agreement_price: x.agreement_price}}.sort{|x, y| x[:agreement_price] <=> y[:agreement_price]}.uniq{|x| x[:bedrooms]}
      @parameters = {fltrs: { project_tower_id: params[:project_tower_id] } }
      @units = ProjectUnit.build_criteria(@parameters).sort{|x, y| y.floor <=> x.floor}.to_a
    elsif params[:stage] == "kyc_details"
      if params[:configuration] == "3d"
        @unit = ProjectUnit.where(sfdc_id: params[:unit_id]).first
      else
        @unit = ProjectUnit.find(params[:unit_id])
      end
      # unless @unit
      #   flash[:message] = "The unit you are looking for is not available"
      #   redirect_to dashboard_path & return
      # end
      SelldoLeadUpdater.perform_async(current_user.id.to_s, "unit_selected")
    end

    @project_units = current_user.project_units
  end

  def gamify_unit_selection
    data = ProjectUnit.build_criteria({
      fltrs: {
        status: ["blocked", "booked_tentative", "booked_confirmed"],
        data_attributes: {
          bedrooms: params[:bedrooms].to_i,
          carpet: "#{params[:carpet].to_f - 50}-#{params[:carpet].to_f + 50}"
        },
      }
    }).count
    respond_to do |format|
      format.json {render json: {message: "#{data + 6} other such #{params[:bedrooms]} BHK apartments sold"}}
    end
  end

  def project_unit
    @project_unit = ProjectUnit.find(params[:project_unit_id])
    authorize @project_unit
  end

  def checkout
    if params[:project_unit_id].present?
      @project_unit = ProjectUnit.find(params[:project_unit_id])
      authorize @project_unit
    else
      authorize(Receipt.new(user: current_user), :new?)
    end
  end

  def checkout_via_email
    if params[:project_unit_id].present? && params[:receipt_id].present?
      receipt = current_user.receipts.where(receipt_id: params[:receipt_id]).where(payment_type: 'blocking').first
      project_unit = ProjectUnit.find(params[:project_unit_id])
      if receipt.present? && receipt.project_unit_id.blank? && project_unit.user_based_status(current_user) == 'available' && receipt.reference_project_unit_id.to_s == project_unit.id.to_s
        params[:project_unit] = {status: 'hold', primary_user_kyc_id: current_user.user_kyc_ids.first}
        hold_project_unit
      else
        flash[:notice] = 'The unit chosen may not be available. You can browse available inventory and block it against the payment done.'
        redirect_to dashboard_path
      end
    end
  end

  def payment
    @receipt = Receipt.new(creator: current_user, user: current_user, payment_mode: 'online', total_amount: ProjectUnit.blocking_amount, payment_type: 'blocking')

    if params[:project_unit_id]
      @project_unit = ProjectUnit.find(params[:project_unit_id])
      authorize @project_unit
      if(current_user.total_unattached_balance >= ProjectUnit.blocking_amount)
        @receipt = current_user.unattached_blocking_receipt
      end

      @receipt.project_unit = @project_unit
    else
      authorize(Receipt.new(user: current_user), :new?)
    end
    if @receipt.payment_type == "blocking"
      @receipt.payment_gateway = 'Razorpay'
    else
      @receipt.payment_gateway = 'Razorpay'
    end
    if @receipt.save
      if @receipt.status == "pending" # if we are just tagging an already successful receipt, we dont need to send the user to payment gateway
        if @receipt.payment_gateway_service.present?
          redirect_to @receipt.payment_gateway_service.gateway_url
        else
          @receipt.update_attributes(status: "failed")
          flash[:notice] = "We couldn't redirect you to the payment gateway, please try again"
          redirect_to dashboard_path
        end
      elsif ['clearance_pending', "success"].include?(@receipt.status)
        redirect_to dashboard_path
      end
    else
      redirect_to dashboard_checkout_path(project_unit_id: @project_unit.id)
    end
  end

  def update_project_unit
    @project_unit = ProjectUnit.find(params[:project_unit_id])
    authorize @project_unit
    respond_to do |format|
      if @project_unit.status == "hold" && @project_unit.update_attributes(permitted_attributes(@project_unit))
        format.html { redirect_to dashboard_path }
        format.json { render json: {project_unit: @project_unit}, status: 200 }
      else
        flash[:notice] = 'Could not update the project unit. Please retry'
        format.html { redirect_to request.referer.present? ? request.referer : dashboard_path }
        format.json { render json: {errors: @project_unit.errors.full_messages.uniq}, status: 422 }
      end
    end
  end

  def update_co_applicants
    @project_unit = ProjectUnit.find(params[:project_unit_id])
    authorize @project_unit
    @project_unit.attributes = permitted_attributes(@project_unit)
    respond_to do |format|
      if @project_unit.save
        format.html { redirect_to dashboard_path }
      else
        flash[:notice] = 'We cannot process your request at this time. Please retry'
        format.html { redirect_to dashboard_path }
      end
    end
  end

  def hold_project_unit
    @project_unit = ProjectUnit.find(params[:project_unit_id])
    authorize @project_unit
    @project_unit.attributes = permitted_attributes(@project_unit)
    @project_unit.primary_user_kyc_id = current_user.user_kyc_ids.first if @project_unit.primary_user_kyc_id.blank?
    @project_unit.status = "hold"
    @project_unit.user = current_user

    respond_to do |format|
      if @project_unit.save
        format.html { redirect_to dashboard_checkout_path(project_unit_id: @project_unit.id) }
      else
        flash[:notice] = 'We cannot process your request at this time. Please retry'
        format.html { redirect_to dashboard_path }
      end
    end
  end

  private
  def set_project_unit
    @project_unit = ProjectUnit.find(params[:project_unit_id])
  end
end
