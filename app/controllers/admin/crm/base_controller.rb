class Admin::Crm::BaseController < ApplicationController
  before_action :set_crm, only: %w[edit update show destroy]

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

  def set_crm
    @crm = ::Crm::Base.find params[:id]
  end
end
