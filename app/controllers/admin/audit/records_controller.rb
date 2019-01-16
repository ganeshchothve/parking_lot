class Admin::Audit::RecordsController < ApplicationController
  # GET/admin/audit/records(.:format)
  def index
    authorize [:admin, Audit::Record]
    @audits = Audit::Record.build_criteria(params).paginate(page: params[:page] || 1, per_page: params[:per_page])
  end
end
