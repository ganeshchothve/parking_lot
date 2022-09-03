class VideosController < ApplicationController
  before_action :authenticate_user!
  before_action :set_videoable
  before_action :set_video, only: [:edit, :update, :show, :destroy]
  before_action :authorize_resource
  around_action :apply_policy_scope, only: :index

  def index
    @videos = Video.where(videoable: @videoable).build_criteria(params).paginate(page: params[:page] || 1, per_page: params[:per_page])
  end

  def new
    @video = Video.new(videoable: @videoable)
    render layout: false
  end

  def create
    @video = Video.new(permitted_attributes([:admin, Video.new(videoable: @videoable)]))
    @video.videoable = @videoable
    if @video.save
      redirect_to videoables_path(videoable: @videoable), notice: I18n.t("controller.notice.created", name: "Video")
    else
      render json: {errors: @video.errors.full_messages}, status: 406
    end
  end

  def show
    render layout: false
  end

  def edit
    render layout: false
  end

  def update
    @video.assign_attributes(permitted_attributes([:admin, Video.new(videoable: @videoable)]))
    if @video.save
      redirect_to videoables_path(videoable: @videoable), notice: I18n.t("controller.notice.updated", name: "Video")
    else
      render json: {errors: @video.errors.full_messages}, status: 406
    end
  end

  def destroy
    respond_to do |format|
      if @video.destroy
        format.html {redirect_to videoables_path(videoable: @videoable), notice: I18n.t("controller.notice.deleted", name: "Video")}
        format.json {render json: {}, status: :ok}
      else
        format.html {render :index, alert: @video.errors.full_messages.to_sentence}
        format.json {render json: {errors: @video.errors.full_messages.to_sentence}, status: :unprocessable_entity}
      end
    end
  end

  private
  def set_videoable
    @videoable = params[:videoable_type].classify.constantize.find params[:videoable_id]
  end

  def set_video
    @video = Video.where(videoable: @videoable).find params[:id]
  end

  def authorize_resource
    # authorize [current_user_role_group, @videoable] unless %w[index destroy].include?(params[:action])
    if params[:action] == "index"
    elsif params[:action] == "new" || params[:action] == "create"
      authorize [current_user_role_group, Video.new(videoable: @videoable)]
    else
      authorize [current_user_role_group, @video]
    end
  end

  def apply_policy_scope
    Video.with_scope(policy_scope(Video.all)) do
      yield
    end
  end
end
