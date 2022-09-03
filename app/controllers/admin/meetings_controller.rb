class Admin::MeetingsController < AdminController
  include MeetingsConcern

  before_action :authenticate_user!
  before_action :set_meeting, only: %i[show edit update]
  before_action :authorize_resource
  around_action :apply_policy_scope, only: %i[index]

  layout :set_layout

  def edit
    render layout: false
  end

  def new
    @meeting = Meeting.new
    render layout: false
  end

  def create
    @meeting = Meeting.new
    @meeting.assign_attributes(permitted_attributes([current_user_role_group, @meeting]))
    @meeting.creator = current_user
    
    respond_to do |format|
      if @meeting.save
        format.html { redirect_to admin_meetings_path, notice: I18n.t('controller.notice.created', name: "Meeting")
        format.json { render json: @meeting, status: :created }
      else
        format.html { render :new }
        format.json { render json: { errors: @meeting.errors.full_messages.uniq }, status: :unprocessable_entity }
      end
    end
  end
end
