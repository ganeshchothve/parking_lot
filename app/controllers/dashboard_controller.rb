class DashboardController < ApplicationController
  before_action :authenticate_user!, only: [:index]
  layout :set_layout

  def index
    authorize :dashboard, :index?
    @project_units = current_user.project_units
  end

  def faqs
  end

  def documents
  end

  def rera
  end

  def tds_process
  end

  def terms_and_conditions
  end

  def gamify_unit_selection
    data = ProjectUnit.build_criteria({
      fltrs: {
        status: ProjectUnit.booking_stages,
        bedrooms: params[:bedrooms].to_i,
        carpet: "#{params[:carpet].to_f - 50}-#{params[:carpet].to_f + 50}"
      }
    }).count
    respond_to do |format|
      format.json {render json: {message: "#{data + 6} other such #{params[:bedrooms]} BHK apartments sold"}}
    end
  end
end
