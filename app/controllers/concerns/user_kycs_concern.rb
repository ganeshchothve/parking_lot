module UserKycsConcern
  extend ActiveSupport::Concern

  #
  # This is the index action for admin, users where they can view all the user kycs.
  #
  # @return [{},{}] records with array of Hashes.
  #
  def index
    @user_kycs = UserKyc.build_criteria params
    @user_kycs = @user_kycs.paginate(page: params[:page] || 1, per_page: params[:per_page])
  end

  #
  # This is the new action for admin, users where they can fill the details for a user kyc record.
  #
  def new
    @user_kyc = UserKyc.new(creator: current_user, user: @lead.user, lead: @lead, first_name: @lead.first_name, last_name: @lead.last_name, email: @lead.email, phone: @lead.phone, booking_portal_client_id: @lead.booking_portal_client.id)
    render layout: false
  end

  #
  # This is the create action for admin, users, called after new.
  #
  def create
    @user_kyc = @lead.user_kycs.build
    update_masked_email_and_phone_if_present
    @user_kyc.assign_attributes(permitted_attributes([current_user_role_group, UserKyc.new(user: @lead.user, lead: @lead) ]))
    @user_kyc.assign_attributes(booking_portal_client_id: @lead.booking_portal_client.id)
    set_user_creator
    authorize [current_user_role_group, @user_kyc]
    respond_to do |format|
      if @user_kyc.save
        format.html { redirect_to home_path(current_user), notice: I18n.t("controller.user_kycs.notice.created") }
        format.json { render json: @user_kyc, status: :created }
      else
        format.html { render :new }
        format.json { render json: { errors: @user_kyc.errors.full_messages.uniq }, status: :unprocessable_entity }
      end
    end
  end

  # This is the edit action for admin, users to edit the details of existing user kyc record.
  #
  def edit
    render layout: false
  end

  #
  # This is the update action for admin, users which is called after edit.
  #
  def update
    respond_to do |format|
      update_masked_email_and_phone_if_present
      if @user_kyc.update(permitted_attributes([current_user_role_group, @user_kyc]))
        format.html { redirect_to home_path(current_user), notice: I18n.t("controller.user_kycs.notice.updated") }
        format.json { render json: @user_kyc }
      else
        format.html { render :edit }
        format.json { render json: { errors: @user_kyc.errors.full_messages.uniq }, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_lead
    @lead = Lead.where(booking_portal_client_id: current_client.id, id: params[:lead_id]).first if params[:lead_id].present?
    @lead = @user_kyc.lead if @user_kyc.present?
    @lead = Lead.where(user_id: current_user, project_id: current_project.id, booking_portal_client_id: current_client.id).first if @lead.blank? && current_project.present?
    redirect_to home_path(current_user), alert: t('controller.leads.alert.not_found') unless @lead
  end

  def set_user_kyc
    @user_kyc = UserKyc.where(booking_portal_client_id: current_client.try(:id), id: params[:id]).first
  end

  def apply_policy_scope
    custom_scope = UserKyc.where(UserKyc.user_based_scope(current_user, params))
    UserKyc.with_scope(policy_scope(custom_scope)) do
      yield
    end
  end

  def update_masked_email_and_phone_if_present
    if @user_kyc.maskable_field?(current_user)
      params[:user_kyc].delete :phone if params.dig(:user_kyc, :phone).blank?
      params[:user_kyc].delete :email if params.dig(:user_kyc, :email).blank?
    end
  end

end
