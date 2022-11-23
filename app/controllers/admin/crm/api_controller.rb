class Admin::Crm::ApiController < ApplicationController
  before_action :set_crm
  before_action :set_api, only: %w[edit update destroy]
  before_action :authorize_resource
  
  def new
    @api = params[:type].constantize.new(base_id: @crm.id, booking_portal_client_id: current_client.id)
    render layout: false
  end

  def create
    @api = params[:type].constantize.new(base_id: @crm.id, booking_portal_client_id: current_client.id)
    @api.assign_attributes(permitted_attributes([current_user_role_group, @api]))
    respond_to do |format|
      if @api.save
        format.html { redirect_to admin_crm_base_path(@crm), notice: I18n.t("controller.apis.notice.added") }
        format.json { render json: @api, status: :created }
      else
        format.html { render :new }
        format.json { render json: { errors: @api.errors.full_messages.uniq }, status: :unprocessable_entity }
      end
    end
  end

  def edit
    render layout: false
  end

  def update
    @api.update_attributes(permitted_attributes([current_user_role_group, @api]))
    respond_to do |format|
      if @api.save
        format.html { redirect_to admin_crm_base_path(@crm), notice: I18n.t("controller.apis.notice.updated") }
        format.json { render json: @api, status: :created }
      else
        format.html { render :new }
        format.json { render json: { errors: @api.errors.full_messages.uniq }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    respond_to do |format|
      if @api.destroy
        format.html { redirect_to admin_crm_base_path(@crm), notice: I18n.t("controller.apis.notice.removed") }
      else
        format.html { redirect_to admin_crm_base_path(@crm), notice: I18n.t("controller.apis.notice.cannot_removed") }
      end
    end
  end

  def show_response
    @api = Crm::Api.where(id: params[:api_id], booking_portal_client_id: current_client.try(:id)).first
    @resource = @api.resource_class.constantize.find params[:resource_id]
    @response = @api.execute(@resource)
    if request.xhr?
      render layout: false
    else
      redirect_to request.referrer || dashboard_path, notice: I18n.t("controller.apis.notice.request_processed")
    end
  end

  private

  def set_api
    @api = params[:type].constantize.unscoped.where(booking_portal_client_id: current_client.try(:id), id: params[:id]).first
    redirect_to admin_crm_base_path(@crm), alert: I18n.t("controller.apis.alert.not_found") if @api.blank?
  end

  def set_crm
    @crm = ::Crm::Base.where(booking_portal_client_id: current_client.try(:id), id: params[:base_id]).first
  end

  def authorize_resource
    if params[:action] == 'index'
      authorize [current_user_role_group, Crm::Api]
    elsif %w[new create show_response].include?(params[:action])
      authorize [current_user_role_group, params[:type].constantize.new()]
    else
      authorize [current_user_role_group, @api]
    end
  end
end
