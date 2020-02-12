class Admin::Crm::ApiController < ApplicationController

  before_action :set_api, only: %w[edit update destroy]
  before_action :set_crm
  
  def new
    @api = ::Crm::Api.new(crm_id: @crm.id)
    render layout: false
  end

  def create
    @api = associated_class.new(crm_id: @crm.id)
    @api.assign_attributes(api_params)
    respond_to do |format|
      if @api.save
        format.html { redirect_to admin_crm_base_path(@crm), notice: 'en.yml' }
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
        format.html { redirect_to admin_crm_base_path(@crm), notice: 'en.yml' }
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
        format.html { redirect_to admin_crm_base_path(@crm), notice: 'en.yml' }
      else
        format.html { redirect_to admin_crm_base_path(@crm), notice: 'en.yml' }
      end
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
end
