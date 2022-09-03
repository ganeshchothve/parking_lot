module AnnouncementsConcern
  extend ActiveSupport::Concern

  #
  # This is the index action for admin, users where they can view all the meetings.
  #
  # @return [{},{}] records with array of Hashes.
  #
  def index
    @announcements = Announcement.build_criteria params
    if params[:fltrs].present? && params[:fltrs][:_id].present?
      redirect_to admin_announcement_path(params[:fltrs][:_id])
    else
      @announcements = @announcements.paginate(page: params[:page] || 1, per_page: params[:per_page])
    end
    respond_to do |format|
      format.json { render json: @announcements.as_json(methods: [:photo_assets_json, :collateral_assets_json]) }
      format.html { render 'announcements/index' }
    end
  end

  #
  # This show action for admin, users where they can view details of a particular meetings.
  #
  # @return [{}] record with array of Hashes.
  #
  def show
    respond_to do |format|
      format.json { render json: @announcement.as_json(methods: [:photo_assets_json, :collateral_assets_json]) }
      format.html { render 'announcements/show', layout: false }
    end  
  end

  def update
    attrs = permitted_attributes([current_user_role_group, @announcement])
    @announcement.assign_attributes(attrs)
    
    respond_to do |format|
      if @announcement.save
        format.json { render json: @announcement }
      else
        format.json { render json: { errors: @announcement.errors.full_messages.uniq }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    respond_to do |format|
      if @announcement.destroy
        format.html { redirect_to admin_announcements_path, notice: 'Announcement deleted successfully.' }
        format.json { render json: @announcement, status: :ok }
      else
        format.html { redirect_to admin_announcements_path }
        format.json { render json: { errors: @announcement.errors.full_messages.uniq }, status: :unprocessable_entity }
      end
    end
  end

  private
  def authorize_resource
    if params[:action] == 'index' || params[:action] == 'export'
      authorize [:admin, Announcement]
    elsif params[:action] == 'new'
      authorize [:admin, Announcement.new]
    elsif params[:action] == 'create'
      authorize [:admin, Announcement.new(permitted_attributes([:admin, Announcement.new]))]
    else
      authorize [:admin, @announcement]
    end
  end

  def apply_policy_scope
    custom_scope = Announcement.where(Announcement.user_based_scope(current_user, params))
    Announcement.with_scope(policy_scope(custom_scope)) do
      yield
    end
  end

  def set_announcement
    @announcement = Announcement.where(id: params[:id]).first
    redirect_to root_path, alert: 'Announcement Not Found' if @announcement.blank?
  end
end
