class Api::V1::LeadsController < ApisController
  before_action :reference_ids_present?, :set_project, :create_or_set_user, :set_manager_through_reference_id, only: :create
  before_action :set_lead_and_user, except: :create
  before_action :add_third_party_reference_params, :modify_params

  #
  # The create action always creates a new user account (if does not exist) & new lead alongwith storing reference ids of third party CRM system.
  #
  # POST  /api/v1/leads
  #
  # {
  #   lead: {
  #     first_name: 'Test',
  #     last_name: 'User',
  #     email: 'test@example.com',
  #     phone: '+919876543210',
  #     stage: "qualified",
  #     sitevisit_date: "11/11/2020", #format - dd/mm/yyyy
  #     revisit_count: 2,
  #     last_revisit_date: "12/11/2020", #format - dd/mm/yyyy
  #     project_id: <project_reference_id>,
  #     user_id: <user_tpr_id> # optional,
  #     reference_id: <lead_reference_id>,
  #     manager_id: <channel_partner_reference_id>
  #   }
  # }
  def create
    unless Lead.reference_resource_exists?(@crm.id, params[:lead][:reference_id])
      @lead = @user.leads.build(lead_create_params)
      @lead.booking_portal_client_id = @current_client.id

      # Add manager in referenced_manager_ids array on lead for future reference.
      if @manager
        @lead.referenced_manager_ids ||= []
        (@lead.referenced_manager_ids << @manager.id).uniq!
      end

      if @lead.save
        @message = I18n.t("controller.leads.notice.created")
        render json: {user_id: @user.id, lead_id: @lead.id, message: @message}, status: :created
      else
        @errors = @lead.errors.full_messages.uniq
        render json: {errors: @errors}, status: :unprocessable_entity
      end
    else
      @errors = [I18n.t("controller.leads.errors.lead_reference_id_already_exists", name: "#{params[:lead][:reference_id]}")]
      render json: {errors: @errors}, status: :unprocessable_entity
    end
  end

  #
  # The update action will update the details of an existing lead using the reference_id for identification.
  #
  # PATCH     /api/v1/leads/:reference_id
  #
  # {
  #   lead: {
  #     email: 'test@example.com',
  #     phone: '+919876543210',
  #     stage: "qualified",
  #     sitevisit_date: "11/11/2020", #format - dd/mm/yyyy
  #     revisit_count: 2,
  #     last_revisit_date: "12/11/2020", #format - dd/mm/yyyy
  #     reference_id: <lead_reference_id>
  #   }
  # }
  #
  def update
    unless Lead.reference_resource_exists?(@crm.id, params[:lead][:reference_id])
      @lead.assign_attributes(lead_update_params)
      if @lead.save
        @message = I18n.t("controller.leads.notice.updated")
        render json: {user_id: @lead.user_id, lead_id: @lead.id, message: @message}, status: :ok
      else
        @errors = @lead.errors.full_messages.uniq
        render json: {errors: @errors}, status: :unprocessable_entity
      end
    else
      @errors = [I18n.t("controller.leads.errors.lead_reference_id_already_exists", name: "#{params[:lead][:reference_id]}")]
      render json: {errors: @errors}, status: :unprocessable_entity
    end
  end

  private

  # Checks if the required reference_id's are present. reference_id is the third party CRM resource id.
  def reference_ids_present?
    unless params.dig(:lead, :project_id).present?
      @errors = [I18n.t("controller.leads.errors.project_id_required")]
      render json: { errors: @errors }, status: :bad_request and return
    end
    unless params.dig(:lead, :reference_id).present?
      @errors = [I18n.t("controller.leads.errors.lead_reference_id_required")]
      render json: { errors: @errors }, status: :bad_request and return
    end
  end

  # Sets or creates the user object if it doesn't exists.
  def create_or_set_user
    unless @user = User.or(check_and_build_query_for_finding_user).where(booking_portal_client_id: @current_client.try(:id)).first
      @user = User.new(user_create_params)
      @user.booking_portal_client_id = @current_client.id
      @user.assign_attributes(is_active: false) # Ruwnal Specific. TODO: Remove this for generic
      @user.skip_confirmation! # TODO: Remove this when customer login needs to be given
      if @user.save
        @user.update_external_ids(user_third_party_reference_params, @crm.id) if user_third_party_reference_params
      else
        @errors = @user.errors.full_messages.uniq
        render json: {errors: @errors}, status: :unprocessable_entity
      end
    end
  end

  def check_and_build_query_for_finding_user
    query = []
    query << {email: params.dig(:lead, :email).to_s.downcase} if params.dig(:lead, :email).present?
    query << {phone: params.dig(:lead, :phone)} if params.dig(:lead, :phone).present?
    if query.present?
      @errors = [I18n.t("controller.leads.errors.email_or_phone_required")]
      render json: {errors: @errors}, status: :bad_request and return if User.or(query).count > 1
    else
      @errors = [I18n.t("controller.leads.errors.email_phone_not_match")]
      render json: { errors: @errors }, status: :bad_request and return
    end
    query
  end

  def set_project
    unless project_reference_id = params.dig(:lead, :project_id).presence
      @errors = [I18n.t("controller.leads.errors.project_id_required")]
      render json: { errors: @errors }, status: :bad_request
    else
      # set project
      @project = Project.where(booking_portal_client_id: @current_client.try(:id), "third_party_references.crm_id": @crm.id, "third_party_references.reference_id": project_reference_id).first
      unless @project
        @errors = [I18n.t("controller.projects.errors.project_reference_id_not_found", name: "#{project_reference_id}")]
        render json: { errors: @errors }, status: :not_found and return
      end

      # modify params
      params[:lead][:project_id] = @project.id.to_s
    end
  end

  def add_third_party_reference_params
    if lead_reference_id = params.dig(:lead, :reference_id).presence
      # add third party references
      tpr_attrs = {
        crm_id: @crm.id.to_s,
        reference_id: lead_reference_id
      }
      if @lead
        tpr = @lead.third_party_references.where(reference_id: params[:id], crm_id: @crm.id).first
        tpr_attrs[:id] = tpr.id.to_s if tpr
      end
      params[:lead][:third_party_references_attributes] = [ tpr_attrs ]
    end
  end

  def set_lead_and_user
    @lead = Lead.where(booking_portal_client_id: @current_client.try(:id), "third_party_references.crm_id": @crm.id, "third_party_references.reference_id": params[:id]).first
    @resource = @lead if @lead.present?
    unless @lead.present?
      @errors = [I18n.t("controller.leads.errors.lead_reference_id_not_found", name: "#{params[:id]}")]
      render json: { errors: @errors }, status: :not_found unless @lead
    end
    @user = @lead.user
  end

  # Allows only certain parameters to be saved and updated.
  def lead_create_params
    params.require(:lead).permit(:first_name, :last_name, :email, :phone, :stage, :sitevisit_date, :revisit_count, :last_revisit_date, :project_id, :manager_id, third_party_references_attributes: [:crm_id, :reference_id])
  end

  def user_create_params
    params.require(:lead).permit(:first_name, :last_name, :email, :phone)
  end

  def lead_update_params
    params.require(:lead).permit(:first_name, :last_name, :stage, :sitevisit_date, :revisit_count, :last_revisit_date, third_party_references_attributes: [:id, :reference_id])
  end

  def third_party_reference_params
    params.require(:lead).permit(Lead::THIRD_PARTY_REFERENCE_IDS)
  end

  def user_third_party_reference_params
    { reference_id: params[:lead][:user_id] } if params.dig(:lead, :user_id).present?
  end

  def set_manager_through_reference_id
    if manager_reference_id = params.dig(:lead, :manager_id).presence
      @manager = User.where(booking_portal_client_id: @current_client.try(:id), "third_party_references.crm_id": @crm.id, "third_party_references.reference_id": manager_reference_id).first
      if @manager
        # modify params
        params[:lead][:manager_id] = @manager.id.to_s
      else
        @errors = [I18n.t("controller.projects.errors.manager_reference_id_not_found", name: "#{manager_reference_id}")]
        render json: {errors: @errors}, status: :not_found and return
      end
    end
  end

  def modify_params
    errors = []
    begin
      params[:lead][:sitevisit_date] = Date.strptime(params.dig(:lead, :sitevisit_date), "%d/%m/%Y") if params.dig(:lead, :sitevisit_date).present?
    rescue ArgumentError
      errors << I18n.t("controller.site_visits.errors.invalid_date_format")
    end
    begin
      params[:lead][:last_revisit_date] = Date.strptime(params.dig(:lead, :last_revisit_date), "%d/%m/%Y") if params.dig(:lead, :last_revisit_date).present?
    rescue ArgumentError
      errors << I18n.t("controller.site_visits.errors.revisit_invalid_date_format")
    end
    errors << I18n.t("controller.site_visits.errors.revisit_count")if params.dig(:lead, :revisit_count).present? && !params.dig(:lead, :revisit_count).is_a?(Integer)
    @errors = errors
    render json: { errors: @errors },status: :unprocessable_entity and return if @errors.present?
  end

end
