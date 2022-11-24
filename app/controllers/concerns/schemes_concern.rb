module SchemesConcern
  extend ActiveSupport::Concern

  #
  # This is the index action for admin and buyer, users where they can view all the schemes.
  #
  # @return [{},{}] records with array of Hashes.
  #
  def index
    @schemes = Scheme.build_criteria params
    @schemes = @schemes.paginate(page: params[:page] || 1, per_page: params[:per_page])
    respond_to do |format|
      format.json { render json: @schemes }
      format.html {}
    end
  end

  def authorize_resource
    if params[:action] == 'index'
      authorize [current_user_role_group, Scheme]
    elsif params[:action] == 'new' || params[:action] == 'create'
      authorize [current_user_role_group, Scheme.new(created_by: current_user, booking_portal_client_id: current_user.booking_portal_client_id)]
    else
      authorize [current_user_role_group, @scheme]
    end
  end

  def apply_policy_scope
    custom_scope = if @project_tower.present?
                     @project_tower.schemes
                   elsif @project.present?
                     @project.schemes
                   else
                     Scheme.where(booking_portal_client_id: current_client.try(:id))
                   end
    custom_scope = custom_scope.filter_by_can_be_applied_by(current_user.role) unless current_user.role.in?(%w(admin superadmin))
    _role = if current_user.role?('channel_partner')
              current_user.role
            elsif current_user.manager_role?('channel_partner')
              current_user.manager_role
            end
    custom_scope = custom_scope.filter_by_can_be_applied_by_role(_role).filter_by_default_for_user_id(current_user.id) if _role
    custom_scope = custom_scope.where(Scheme.user_based_scope(current_user,params))

    Scheme.with_scope(policy_scope(custom_scope)) do
      yield
    end
  end

  def set_project
    @project = Project.where(booking_portal_client_id: current_client.try(:id), id: params[:project_id]).first if params[:project_id].present?
  end
end
