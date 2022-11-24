module UserRequestsConcern
  extend ActiveSupport::Concern

  #
  # This is the index action for admin, users where they can view all the user requests.
  #
  # @return [{},{}] records with array of Hashes.
  #
  def index
    @user_requests = associated_class.build_criteria params
    @user_requests = @user_requests.paginate(page: params[:page] || 1, per_page: params[:per_page])
  end

  #
  # This is the new action for admin, users where they can fill the details for a new user request.
  #
  def new
    @user_request = associated_class.new(
                                    user_id: @user.id, 
                                    lead: @lead,
                                    booking_portal_client_id: current_user.booking_portal_client.id
                                    )
    @user_request.project = @lead.project if @lead.present?
    @user_request.requestable_id = params[:requestable_id] if params[:requestable_id].present?
    @user_request.requestable_type = params[:requestable_type] if params[:requestable_type].present?
    render layout: false
  end

  #
  # This show action for admin, users where they can view details of a particular user request.
  #
  # @return [{}] record with array of Hashes.
  #
  def show
    @user_request = associated_class.find(params[:id])
  end

  # This is the edit action for admin, users to edit the details of existing user request.
  #
  def edit
    render layout: false
  end

  private

  def set_user_request
    @user_request = associated_class.where(booking_portal_client_id: current_client.try(:id), id: params[:id]).first
  end

  def permitted_user_request_attributes
    attributes = permitted_attributes([current_user_role_group, @user_request])
    if attributes[:notes_attributes].present?
      attributes[:notes_attributes].each do |k, v|
        attributes[:notes_attributes].delete(k) if v['note'].blank?
      end
    end
    attributes
  end

  def associated_class
    @associated_class = if params[:request_type] == 'swap'
                          UserRequest::Swap
                        elsif params[:request_type] == 'cancellation'
                          UserRequest::Cancellation
                        elsif params[:request_type] == 'general'
                          UserRequest::General
                        else
                          UserRequest
                        end
  end

  def authorize_after_action
    authorize [current_user_role_group, @user_request] if params[:action == 'new'] || params[:action == 'show']
  end

  def authorize_resource
    if params[:action] == 'index' || params[:action] == 'export'
      authorize [current_user_role_group, UserRequest]
    elsif params[:action] == 'new' || params[:action] == 'create'
      object = associated_class.new(user_id: @user.id, lead: @lead)
      object.project = @lead.project if @lead.present?
      authorize [current_user_role_group, object]
    else
      authorize [current_user_role_group, @user_request]
    end
  end

  def apply_policy_scope
    custom_scope = associated_class.where(associated_class.user_based_scope(current_user, params))
    associated_class.with_scope(policy_scope(custom_scope)) do
      yield
    end
  end
end
