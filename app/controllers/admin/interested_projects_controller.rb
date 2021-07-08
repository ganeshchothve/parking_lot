class Admin::InterestedProjectsController < AdminController
  before_action :authenticate_user!
  before_action :set_user
  before_action :set_interested_project, only: [:edit, :update]
  before_action :authorize_resource
  #around_action :apply_policy_scope, only: %i[index]

  def index
    @interested_projects = @user.interested_projects.build_criteria params
    @interested_projects = @interested_projects.paginate(page: params[:page] || 1, per_page: params[:per_page])
  end

  def create
    @interested_project = @user.interested_projects.build(permitted_attributes([:admin, InterestedProject.new]))
    respond_to do |format|
      if @interested_project.save
        format.html { redirect_to request.referer, notice: 'Project successfully subscribed.' }
      else
        format.html { redirect_to request.referer, alert: @interested_project.errors.full_messages }
        format.json { render json: { errors: @interested_project.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def edit
    render layout: false
  end

  def update
    @interested_project.assign_attributes(permitted_attributes([:admin, @interested_project]))
    respond_to do |format|
      if (params.dig(:interested_project, :event).present? ? @interested_project.send("#{params.dig(:interested_project, :event)}!") : @interested_project.save)
        format.html { redirect_to admin_leads_path, notice: 'Interested Project successfully updated.' }
      else
        format.html { render :edit }
        format.json { render json: { errors: @interested_project.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_user
    @user = User.where(id: params[:user_id]).first
    redirect_to root_path, alert: t('controller.users.set_user_missing') if @user.blank?
  end

  def set_interested_project
    @interested_project = @user.interested_projects.where(id: params[:id]).first
    redirect_to root_path, alert: t('controller.users.set_interested_project_missing') if @interested_project.blank?
  end

  def authorize_resource
    if %w[index create].include?(params[:action])
      authorize [current_user_role_group, InterestedProject]
    else
      authorize [current_user_role_group, @interested_project]
    end
  end

end
