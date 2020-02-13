class Admin::Crm::ApiController < ApplicationController
  before_action :set_api, only: %w[edit update destroy]
  before_action :set_crm
  
  def new
    @api = ::Crm::Api.new(base_id: @crm.id)
    render layout: false
  end

  def create
    @api = associated_class.new(base_id: @crm.id)
    @api.assign_attributes(api_params)
    respond_to do |format|
      if @api.save
        format.html { redirect_to admin_crm_base_path(@crm), notice: 'API configuration is added successfully' }
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
    @api.update_attributes(permitted_attributes([:admin, @api]))
    respond_to do |format|
      if @api.save
        format.html { redirect_to admin_crm_base_path(@crm), notice: 'API configuration is updated successfully' }
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
        format.html { redirect_to admin_crm_base_path(@crm), notice: 'API configuration is removed successfully' }
      else
        format.html { redirect_to admin_crm_base_path(@crm), notice: 'API configuration is cannot be removed' }
      end
    end
  end

  def show_response
    api = Crm::Api.find params[:api_id]
    record = api.resource_class.constantize.find params[:record_id]
    @response = api.execute(record)
    if @response.blank? || !@response.respond_to?(:html_safe)
      redirect_to request.referrer || dashboard_path, notice: 'There was some error. Please contact administrator'
    end
  end

  private

  def api_params
    params.require(:crm_api).permit(policy(@api).permitted_attributes)
  end
  def associated_class
    @associated_class = if params[:crm_api][:request_type] == 'get'
                          ::Crm::Api::Get
                        elsif params[:crm_api][:request_type] == 'post'
                          ::Crm::Api::Post
                        else
                          ::Crm::Api
                        end
  end

  def set_api
    @api = ::Crm::Api.find params[:id]
  end

  def set_crm
    @crm = ::Crm::Base.find params[:base_id]
  end

  def authorize_resource
    if params[:action] == 'index'
      authorize [current_user_role_group, Crm::Api]
    elsif params[:action] == 'new' || params[:action] == 'create'
      authorize [current_user_role_group, Crm::Api.new()]
    else
      authorize [current_user_role_group, @api]
    end
  end
end
