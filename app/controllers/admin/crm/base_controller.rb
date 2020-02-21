class Admin::Crm::BaseController < ApplicationController
  before_action :set_crm, only: %w[edit update show destroy]
  before_action :authorize_resource

  def index
    @crms = ::Crm::Base.all.paginate(page: params[:page] || 1, per_page: params[:per_page])
  end

  def new
    @crm = ::Crm::Base.new
    render layout: false
  end

  def create
    @crm = ::Crm::Base.new
    @crm.assign_attributes(permitted_attributes([:admin, @crm]))
    respond_to do |format|
      if @crm.save
        format.html { redirect_to admin_crm_base_index_path, notice: t('controller.crm/base.create.success') }
        format.json { render json: @crm, status: :created }
      else
        format.html { render :new }
        format.json { render json: { errors: @crm.errors.full_messages.uniq }, status: :unprocessable_entity }
      end
    end
  end

  def edit
    render layout: false
  end

  def update
    @crm.update_attributes(permitted_attributes([:admin, @crm]))
    respond_to do |format|
      if @crm.save
        format.html { redirect_to admin_crm_base_index_path, notice: t('controller.crm/base.update.success') }
        format.json { render json: @crm, status: :created }
      else
        format.html { render :new }
        format.json { render json: { errors: @crm.errors.full_messages.uniq }, status: :unprocessable_entity }
      end
    end
  end

  def show
    @apis = @crm.apis.paginate(page: params[:page] || 1, per_page: params[:per_page])
  end

  def destroy
    respond_to do |format|
      if @crm.destroy
        format.html { redirect_to admin_crm_base_index_path, notice: t('controller.crm/base.destroy.success') }
      else
        format.html { redirect_to admin_crm_base_index_path, notice: t('controller.crm/base.destroy.failure') }
      end
    end
  end

  def choose_crm
    @resource = params[:resource_class].constantize.find params[:resource_id]
    @apis = Crm::Api.where(resource_class: params[:resource_class].to_s)
    @crms = Crm::Base.where(id: {"$in": @apis.pluck(:base_id)})
  end

  private

  def set_crm
    @crm = ::Crm::Base.find params[:id]
  end

  def authorize_resource
    if params[:action] == 'index' || params[:action] == 'choose_crm'
      authorize [current_user_role_group, Crm::Base]
    elsif params[:action] == 'new' || params[:action] == 'create'
      authorize [current_user_role_group, Crm::Base.new()]
    else
      authorize [current_user_role_group, @crm]
    end
  end
end
