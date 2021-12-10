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
    render 'announcements/index', layout: false
  end

  #
  # This show action for admin, users where they can view details of a particular meetings.
  #
  # @return [{}] record with array of Hashes.
  #
  def show
    render 'announcements/show', layout: false
  end

  def update
    attrs = permitted_attributes([current_user_role_group, @announcement])
    @announcement.assign_attributes(attrs)
    
    respond_to do |format|
      if (params.dig(:announcement, :event).present? ? @announcement.send("#{params.dig(:announcement, :event)}!") : @announcement.save)
        if attrs[:toggle_participant_id].present?
          toggle_interest_form = render_to_string(partial: 'meetings/toggle_interest_form', locals: {announcement: @announcement}, layout: false)
          json = @announcement.as_json
          json[:html] = toggle_interest_form
          json[:reload] = (params[:reload].present? && params[:reload].to_s == "true")
        end
        format.json { render json: json.to_json }
      else
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
    @announcement = Announcement.find(params[:id])
  end
end
