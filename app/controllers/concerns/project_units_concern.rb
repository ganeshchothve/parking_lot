module ProjectUnitsConcern
  extend ActiveSupport::Concern

  #
  # This edit action for Admin, users to edit the details of existing project unit record.
  #
  def edit
    render layout: false
  end

  private

  def set_project_unit
    @project_unit = ProjectUnit.find(params[:id])
  end
end
