class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
  end

  def project_units
    @project_units = current_user.project_units
  end

  def project_unit
    @project_unit = ProjectUnit.find(params[:project_unit_id])
  end

  def receipts
    @receipts = current_user.receipts
  end
end
