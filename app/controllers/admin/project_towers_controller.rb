class Admin::ProjectTowersController < AdminController

  def index
    # authorize [:admin, ProjectTower]
    @project_towers = ProjectTower.build_criteria(params)#.paginate(page: params[:page] || 1, per_page: params[:per_page])

    respond_to do |format|
      format.json { render json: @project_towers }
      format.html {}
    end
  end
end
