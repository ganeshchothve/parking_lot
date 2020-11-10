class Api::V1::LeadsController < ApisController
  before_action :reference_ids_present?, :set_project, :create_or_set_user, :set_manager_through_reference_id, only: :create
  before_action :set_user, :set_lead, except: :create
  before_action :add_third_party_reference_params

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
  #     project_id: <project_reference_id>,
  #     user_id: <user_tpr_id> # optional,
  #     reference_id: <lead_reference_id>,
  #     manager_id: <channel_partner_reference_id>
  #   }
  # }
  #
  def create
    unless @user.leads.reference_resource_exists?(@crm.id, params[:lead][:reference_id])
      @lead = @user.leads.build(lead_create_params)

      # Add manager in referenced_manager_ids array on lead for future reference.
      if @manager
        @lead.referenced_manager_ids ||= []
        (@lead.referenced_manager_ids << @manager.id).uniq!
      end

      if @lead.save
        render json: {user_id: @user.id, lead_id: @lead.id, message: 'Lead successfully created.'}, status: :created
      else
        render json: {errors: @lead.errors.full_messages.uniq}, status: :unprocessable_entity
      end
    else
      render json: {errors: ["Lead with reference_id '#{params[:lead][:reference_id]}' already exists"]}, status: :unprocessable_entity
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
  #     reference_id: <lead_reference_id>
  #   }
  # }
  #
  def update
    unless @user.leads.reference_resource_exists?(@crm.id, params[:lead][:reference_id])
      @lead.assign_attributes(lead_update_params)
      if @lead.save
        render json: {user_id: @lead.user_id, lead_id: @lead.id, message: 'Lead successfully updated.'}, status: :ok
      else
        render json: {errors: @lead.errors.full_messages.uniq}, status: :unprocessable_entity
      end
    else
      render json: {errors: ["Lead with reference_id '#{params[:lead][:reference_id]}' already exists"]}, status: :unprocessable_entity
    end
  end

  private

  # Checks if the required reference_id's are present. reference_id is the third party CRM resource id.
  def reference_ids_present?
    render json: { errors: ['project_id is required to create Lead'] }, status: :bad_request and return unless params.dig(:lead, :project_id).present?
    render json: { errors: ['Lead reference_id is required'] }, status: :bad_request and return unless params.dig(:lead, :reference_id).present?
  end

  # Sets or creates the user object if it doesn't exists.
  def create_or_set_user
    unless @user = User.or(check_and_build_query_for_finding_user).first
      @user = User.new(user_create_params)
      @user.assign_attributes(is_active: false) # Ruwnal Specific. TODO: Remove this for generic
      if @user.save
        @user.update_external_ids(user_third_party_reference_params, @crm.id) if user_third_party_reference_params
        @user.confirm # Runwal Specific. TODO: Remove this for generic & follow devise confirmation flow
      else
        render json: {errors: @user.errors.full_messages.uniq}, status: :unprocessable_entity
      end
    end
  end

  def check_and_build_query_for_finding_user
    query = []
    query << {email: params.dig(:lead, :email)} if params.dig(:lead, :email).present?
    query << {phone: params.dig(:lead, :phone)} if params.dig(:lead, :phone).present?
    if query.present?
      render json: {errors: ["User email & phone doesn't match"]}, status: :bad_request and return if User.or(query).count > 1
    else
      render json: { errors: ['User email or phone is required'] }, status: :bad_request and return
    end
    query
  end

  def set_project
    unless project_reference_id = params.dig(:lead, :project_id).presence
      render json: { errors: ['project_id is required for creating lead'] }, status: :bad_request
    else
      # set project
      @project = Project.where("third_party_references.crm_id": @crm.id, "third_party_references.reference_id": project_reference_id).first
      render json: { errors: ["Project with reference id '#{project_reference_id}' not found"] }, status: :not_found and return unless @project

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

  def set_user
    @user = User.or(check_and_build_query_for_finding_user).first
    render json: { errors: ["User with this email/phone not found"] }, status: :not_found unless @user
  end

  def set_lead
    @lead = @user.leads.where("third_party_references.crm_id": @crm.id, "third_party_references.reference_id": params[:id]).first
    render json: { errors: ["Lead with reference_id '#{params[:id]}' not found"] }, status: :not_found unless @lead
  end

  # Allows only certain parameters to be saved and updated.
  def lead_create_params
    params.require(:lead).permit(:project_id, :manager_id, third_party_references_attributes: [:crm_id, :reference_id])
  end

  def user_create_params
    params.require(:lead).permit(:first_name, :last_name, :email, :phone)
  end

  def lead_update_params
    params.require(:lead).permit(third_party_references_attributes: [:id, :reference_id])
  end

  def third_party_reference_params
    params.require(:lead).permit(Lead::THIRD_PARTY_REFERENCE_IDS)
  end

  def user_third_party_reference_params
    { reference_id: params[:lead][:user_id] } if params.dig(:lead, :user_id).present?
  end

  def set_manager_through_reference_id
    if manager_reference_id = params.dig(:lead, :manager_id).present?
      @manager = User.where("third_party_references.crm_id": @crm.id, "third_party_references.reference_id": manager_reference_id).first
      if @manager
        # modify params
        params[:lead][:manager_id] = @manager.id.to_s
      else
        render json: {errors: ["Manager with reference id '#{manager_reference_id}' not found"]}, status: :not_found and return
      end
    end
  end

end
