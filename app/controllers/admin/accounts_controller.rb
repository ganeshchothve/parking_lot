class Admin::AccountsController < AdminController
  include AccountConcern
  before_action :set_account, except: %i[index export new create]
  before_action :authorize_resource
  # set_account, associated_class, authorize_resource from AccountssConcern

  # index
  # GET /admin/:request_type/accounts

  def index
    @accounts = Account.all
    @accounts = @accounts.paginate(page: params[:page] || 1, per_page: params[:per_page])
    respond_to do |format|
      format.json { render json: @accounts }
      format.html {}
    end
  end

  # new
  # GET /admin/:request_type/accounts/new

  def new
    @account = associated_class.new
    render layout: false
  end

  # show
  # GET /admin/:request_type/accounts/:id

  def show
    respond_to do |format|
      format.json { render json: @account }
      format.html {}
    end
  end

  # edit
  # GET /admin/:request_type/accounts/:id/edit

  def edit
    render layout: false
  end
  #
  # This is the create action for Admin, called after new to create a new account.
  #
  # POST /admin/:request_type/accounts
  #
  def create
    @account = associated_class.new(booking_portal_client_id: current_user.booking_portal_client.id)
    @account.assign_attributes(permitted_attributes([:admin, @account]))
    respond_to do |format|
      if @account.save
        format.html { redirect_to admin_accounts_path, notice: I18n.t("controller.accounts.notice.registered") }
        format.json { render json: @account, status: :created }
      else
        format.html { render :new }
        format.json { render json: { errors: @account.errors.full_messages.uniq }, status: :unprocessable_entity }
      end
    end
  end
  #
  # This is the destroy action for Account.
  #
  #  DELETE admin/accounts/:id
  #
  def destroy
    respond_to do |format|
      if @account.destroy
        format.html { redirect_to admin_accounts_path, notice: I18n.t("controller.accounts.notice.deleted") }
      else
        format.html { redirect_to admin_accounts_path, notice: I18n.t("controller.accounts.notice.cannot_be_deleted") }
      end
    end
  end
  #
  # This is the update action for Account.
  #
  # PATCH  admin/accounts/:id
  #
  def update
    @account.assign_attributes(permitted_attributes([:admin, @account]))

    respond_to do |format|
      if @account.save
        format.html { redirect_to admin_accounts_path, notice: I18n.t("controller.accounts.notice.registered") }
        format.json { render json: @account, status: :created }
      else
        format.html { render :new }
        format.json { render json: { errors: @account.errors.full_messages.uniq }, status: :unprocessable_entity }
      end
    end
  end
end
