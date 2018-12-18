class Admin::Audit::RecordsController < ApplicationController
  def index
    authorize [:admin, Audit::Record]
    @audits = Audit::Record.build_criteria(params).paginate(page: params[:page] || 1, per_page: 15)
  end
end
