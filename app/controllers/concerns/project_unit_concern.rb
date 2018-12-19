module ProjectUnitConcern
  extend ActiveSupport::Concern

  def edit
    render layout: false
  end

  private


  def set_project_unit
    @project_unit = ProjectUnit.find(params[:id])
  end

end
