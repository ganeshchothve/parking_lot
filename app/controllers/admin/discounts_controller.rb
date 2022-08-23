class Admin::DiscountsController < AdminController
  before_action :set_discount, except: %i[index new create]
  before_action :authorize_resource

  # index
  # GET /admin/discounts
  def index
    @discounts = Discount.all
    @discounts = @discounts.paginate(page: params[:page] || 1, per_page: params[:per_page])
    respond_to do |format|
      format.json { render json: @discounts }
      format.html {}
    end
  end

  # new
  # GET /admin/discounts/new
  def new
    @discount = Discount.new
    render layout: false
  end

  # show
  # GET /admin/discounts/:id
  def show
    respond_to do |format|
      format.json { render json: @discount }
      format.html {}
    end
  end

  # edit
  # GET /admin/discounts/:id/edit
  def edit
    render layout: false
  end

  # This is the create action for Admin, called after new to create a new discount.
  #
  # POST /admin/discounts
  def create
    @discount = Discount.new
    @discount.assign_attributes(permitted_attributes([:admin, @discount]))
    respond_to do |format|
      if @discount.save
        format.html { redirect_to admin_discounts_path, notice: "#{t('global.discount.one')} created successfully." }
        format.json { render json: @discount, status: :created }
      else
        format.html { render :new }
        format.json { render json: { errors: @discount.errors.full_messages.uniq }, status: :unprocessable_entity }
      end
    end
  end

  # This is the destroy action for Discount.
  #
  #  DELETE admin/discounts/:id
  def destroy
    respond_to do |format|
      if @discount.destroy
        format.html { redirect_to admin_discounts_path, notice: "#{t('global.discount.one')} deleted successfully." }
      else
        format.html { redirect_to admin_discounts_path, alert: @discount.errors.full_messages.join(' ') }
      end
    end
  end

  # This is the update action for Discount.
  #
  # PATCH  admin/discounts/:id
  def update
    @discount.assign_attributes(permitted_attributes([:admin, @discount]))
    respond_to do |format|
      if @discount.save
        format.html { redirect_to admin_discounts_path, notice: "#{t('global.discount')} updated successfully." }
        format.json { render json: @discount, status: :ok }
      else
        format.html { render :new }
        format.json { render json: { errors: @discount.errors.full_messages.uniq }, status: :unprocessable_entity }
      end
    end
  end

  def update_coupons
    CouponUpdateWorker.perform_async current_user.id
    respond_to do |format|
      format.html { redirect_to admin_discounts_path, notice: t("controller.discounts.update_coupons.success_message") }
    end
  end

  private

  def set_discount
    @discount = Discount.where(id: params[:id]).first
  end

  def authorize_resource
    if %w[index update_coupons].include? params[:action]
      authorize [:admin, Discount]
    elsif params[:action] == 'new' || params[:action] == 'create'
      authorize [:admin, Discount.new]
    else
      authorize [:admin, @discount]
    end
  end
end
