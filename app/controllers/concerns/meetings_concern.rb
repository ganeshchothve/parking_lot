module MeetingsConcern
  extend ActiveSupport::Concern

  #
  # This is the index action for admin, users where they can view all the meetings.
  #
  # @return [{},{}] records with array of Hashes.
  #
  def index
    @meetings = Meeting.build_criteria params
    if params[:fltrs].present? && params[:fltrs][:_id].present?
      redirect_to admin_meeting_path(params[:fltrs][:_id])
    else
      @meetings = @meetings.paginate(page: params[:page] || 1, per_page: params[:per_page])
    end
    render 'meetings/index'
  end

  #
  # This show action for admin, users where they can view details of a particular meetings.
  #
  # @return [{}] record with array of Hashes.
  #
  def show
    render 'meetings/show', layout: false
  end

  def update
    @meeting.assign_attributes(permitted_attributes([current_user_role_group, @meeting]))
    
    respond_to do |format|
      if (params.dig(:meeting, :event).present? ? @meeting.send("#{params.dig(:meeting, :event)}!") : @meeting.save)
        toggle_interest_form = render_to_string(partial: 'meetings/toggle_interest_form', locals: {meeting: @meeting}, layout: false)
        json = @meeting.as_json
        json[:html] = toggle_interest_form
        json[:reload] = (params[:reload].present? && params[:reload].to_s == "true")
        format.json { render json: json.to_json }
      else
        format.json { render json: { errors: @meeting.errors.full_messages.uniq }, status: :unprocessable_entity }
      end
    end
  end

  private
  def find_user_with_reference_id crm_id, reference_id
    _crm = Crm::Base.where(id: crm_id).first
    _user = User.where("third_party_references.crm_id": _crm.try(:id), "third_party_references.reference_id": reference_id ).first
    _user
  end

  def authorize_resource
    if params[:action] == 'index' || params[:action] == 'export'
      authorize [:admin, Meeting]
    elsif params[:action] == 'new'
      authorize [:admin, Meeting.new]
    elsif params[:action] == 'create'
      authorize [:admin, Meeting.new(permitted_attributes([:admin, Meeting.new]))]
    else
      authorize [:admin, @meeting]
    end
  end

  def apply_policy_scope
    custom_scope = Meeting.where(Meeting.user_based_scope(current_user, params))
    Meeting.with_scope(policy_scope(custom_scope)) do
      yield
    end
  end

  def set_meeting
    @meeting = Meeting.find(params[:id])
  end
end
