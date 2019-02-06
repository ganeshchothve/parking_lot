class Admin::AccountsController < ApplicationController
  include AccountConcern
  #around_action :apply_policy_scope, only: [:index]
  # before_action :set_account, except: %i[index export new create update]
  before_action :authorize_resource
  
  def index
    @accounts = Account.all
    @accounts = @accounts.paginate(page: params[:page] || 1, per_page: params[:per_page])
    respond_to do |format|
      format.json { render json: @schemes }
      format.html {}
    end
  end
  def new 
    @account = associated_class.new()
    render layout: false
  end
  def edit 
    render layout: false
  end
  def create
    @account = associated_class.new()
    @account.assign_attributes(permitted_attributes([:admin, @account]))
    respond_to do |format|
      if @account.save
        format.html { redirect_to admin_accounts_path, notice: 'Request registered successfully.' }
        format.json { render json: @account, status: :created }
      else
        format.html { render :new }
        format.json { render json: { errors: @account.errors.full_messages.uniq }, status: :unprocessable_entity }
      end
    end
  end 

  def show
    @receipts = @account.receipts
    respond_to do |format|
      format.json { render json: @account }
      format.html {}
    end
  end
  def destroy
    if @account.receipts.empty?
     @account.destroy
    else
      redirect_to admin_accounts_path, notice: 'Account cannot be deleted.'
    end
    respond_to do |format|
        format.html { redirect_to admin_accounts_path, notice: 'Account deleted successfully.' }
    end
  end
  def update
    @account.assign_attributes(permitted_attributes([:admin,@account]))

    respond_to do |format|
      if @account.save
        format.html { redirect_to admin_accounts_path, notice: 'Request registered successfully.' }
        format.json { render json: @account, status: :created }
      else
        format.html { render :new }
        format.json { render json: { errors: @account.errors.full_messages.uniq }, status: :unprocessable_entity }
      end
    end
  end
end
