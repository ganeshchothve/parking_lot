class Admin::DiscountsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_discount, except: [:index, :export, :new, :create]
  before_action :authorize_resource
  around_action :apply_policy_scope, only: [:index]

  layout :set_layout

  def index
    @discounts = Discount.build_criteria params
    @discounts = @discounts.paginate(page: params[:page] || 1, per_page: 15)
    respond_to do |format|
      if params[:ds].to_s == 'true'
        format.json { render json: @discounts.collect{|d| {id: d.id, name: d.name}} }
        format.html {}
      else
        format.json { render json: @discounts }
        format.html {}
      end
    end
  end

  def show
    @discount = Discount.find(params[:id])
    authorize @discount
  end

  def new
    @discount = Discount.new(created_by: current_user)
    authorize @discount
    render layout: false
  end

  def create
    @discount = Discount.new(created_by: current_user)
    @discount.assign_attributes(permitted_attributes(@discount))

    respond_to do |format|
      if @discount.save
        format.html { redirect_to admin_discounts_path, notice: 'Discount registered successfully and sent for approval.' }
        format.json { render json: @discount, status: :created }
      else
        format.html { render :new }
        format.json { render json: {errors: @discount.errors.full_messages.uniq}, status: :unprocessable_entity }
      end
    end
  end

  def edit
    render layout: false
  end

  def approve_via_email
    @discount.status = 'approved'
    @discount.approved_by = current_user
    respond_to do |format|
      if @discount.save
        format.html { redirect_to admin_discounts_path, notice: 'Discount was successfully updated.' }
        format.json { render json: @discount }
      else
        format.html { render :edit }
        format.json { render json: {errors: @discount.errors.full_messages.uniq}, status: :unprocessable_entity }
      end
    end
  end

  def update
    @discount.assign_attributes(permitted_attributes(@discount))
    @discount.approved_by = current_user if @discount.status_changed? && @discount.status == 'approved'
    respond_to do |format|
      if @discount.save
        format.html { redirect_to admin_discounts_path, notice: 'Discount was successfully updated.' }
      else
        format.html { render :edit }
        format.json { render json: @discount.errors, status: :unprocessable_entity }
      end
    end
  end

  private
  def set_discount
    @discount = Discount.find(params[:id])
  end

  def authorize_resource
    if params[:action] == "index" || params[:action] == 'export'
      authorize Discount
    elsif params[:action] == "new" || params[:action] == "create"
      authorize Discount.new(created_by: current_user)
    else
      authorize @discount
    end
  end

  def apply_policy_scope
    custom_scope = Discount.criteria
    Discount.with_scope(policy_scope(custom_scope)) do
      yield
    end
  end
end
