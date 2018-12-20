class Admin::Audit::RecordsController < ApplicationController
  # GET/admin/audit/records(.:format)                                       
  def index
    authorize [:admin, Audit::Record]
    @audits = Audit::Record.build_criteria(params).paginate(page: params[:page] || 1, per_page: 15)
  end
end
