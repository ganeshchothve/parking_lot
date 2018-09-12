class Admin::SchemesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project
  before_action :set_scheme, except: [:index, :export, :new, :create]
  before_action :authorize_resource
  around_action :apply_policy_scope, only: [:index]

  layout :set_layout

  def index
    @schemes = Scheme.build_criteria params
    @schemes = @schemes.paginate(page: params[:page] || 1, per_page: 15)
    respond_to do |format|
      if params[:ds].to_s == 'true'
        format.json { render json: @schemes.collect{|d| {id: d.id, name: d.name}} }
        format.html {}
      else
        format.json { render json: @schemes }
        format.html {}
      end
    end
  end

  def show
    @scheme = Scheme.find(params[:id])
    authorize @scheme
  end

  def new
    @scheme = Scheme.new(created_by: current_user, booking_portal_client_id: current_user.booking_portal_client_id)
    authorize @scheme
    render layout: false
  end

  def create
    @scheme = Scheme.new(created_by: current_user, booking_portal_client_id: current_user.booking_portal_client_id)
    @scheme.assign_attributes(permitted_attributes(@scheme))

    respond_to do |format|
      if @scheme.save
        format.html { redirect_to admin_schemes_path, notice: 'Scheme registered successfully and sent for approval.' }
        format.json { render json: @scheme, status: :created }
      else
        format.html { render :new }
        format.json { render json: {errors: @scheme.errors.full_messages.uniq}, status: :unprocessable_entity }
      end
    end
  end

  def edit
    render layout: false
  end

  def approve_via_email
    @scheme.status = 'approved'
    @scheme.approved_by = current_user
    respond_to do |format|
      if @scheme.save
        format.html { redirect_to admin_schemes_path, notice: 'Scheme was successfully updated.' }
        format.json { render json: @scheme }
      else
        format.html { render :edit }
        format.json { render json: {errors: @scheme.errors.full_messages.uniq}, status: :unprocessable_entity }
      end
    end
  end

  def update
    @scheme.assign_attributes(permitted_attributes(@scheme))
    @scheme.approved_by = current_user if @scheme.status_changed? && @scheme.status == 'approved'
    respond_to do |format|
      if @scheme.save
        format.html { redirect_to admin_schemes_path, notice: 'Scheme was successfully updated.' }
      else
        format.html { render :edit }
        format.json { render json: @scheme.errors, status: :unprocessable_entity }
      end
    end
  end

  private
  def set_scheme
    @scheme = Scheme.find(params[:id])
  end

  def set_project
    @project = Project.find params[:project_id]
  end

  def authorize_resource
    if params[:action] == "index" || params[:action] == 'export'
      authorize Scheme
    elsif params[:action] == "new" || params[:action] == "create"
      authorize Scheme.new(created_by: current_user, booking_portal_client_id: current_user.booking_portal_client_id)
    else
      authorize @scheme
    end
  end

  def apply_policy_scope
    custom_scope = @project.schemes.criteria
    Scheme.with_scope(policy_scope(custom_scope)) do
      yield
    end
  end
end
