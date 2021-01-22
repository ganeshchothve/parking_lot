class Admin::CpLeadActivitiesController < AdminController

  def index
    @cp_lead_activities = CpLeadActivity.all
    @cp_lead_activities = @cp_lead_activities.paginate(page: params[:page] || 1, per_page: params[:per_page])
    respond_to do |format|
      format.json { render json: @cp_lead_activities }
      format.html {}
    end
  end
end
