# TODO: replace all messages & flash messages
class DashboardController < ApplicationController
  before_action :authenticate_user!, except: [:gamify_unit_selection]
  before_action :set_project_unit, only: [:payment_breakup, :make_remaining_payment]
  layout :set_layout

  def index
    authorize :dashboard, :index?
    @project_units = current_user.project_units
  end

  def payment_breakup
  end

  def make_remaining_payment
  end

  def faq
  end

  def rera
  end

  def tds_process
  end

  def terms_and_conditions
  end

  def project_units
    authorize :dashboard, :project_units?
    @search = current_user.searches.new
    if params[:stage] == "kyc_details"
      if params[:configuration] == "3d"
        @unit = ProjectUnit.where(sfdc_id: params[:unit_id]).first
      else
        @unit = ProjectUnit.find(params[:unit_id])
      end
      SelldoLeadUpdater.perform_async(current_user.id.to_s, "unit_selected")
    end

    @project_units = current_user.project_units
  end

  def gamify_unit_selection
    data = ProjectUnit.build_criteria({
      fltrs: {
        status: ["blocked", "booked_tentative", "booked_confirmed"],
        bedrooms: params[:bedrooms].to_i,
        carpet: "#{params[:carpet].to_f - 50}-#{params[:carpet].to_f + 50}"
      }
    }).count
    respond_to do |format|
      format.json {render json: {message: "#{data + 6} other such #{params[:bedrooms]} BHK apartments sold"}}
    end
  end

  private
  def set_project_unit
    @project_unit = ProjectUnit.find(params[:project_unit_id])
  end
end
