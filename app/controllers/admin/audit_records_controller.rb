class Admin::AuditRecordsController < ApplicationController
  def index
    authorize [:admin, AuditRecord]
    @audits = AuditRecord.build_criteria(params).paginate(page: params[:page] || 1, per_page: 15)
  end

  def show
    authorize [:admin, AuditEntry]
    @audit_entries = AuditEntry.where(audit_id: params[:id])
    respond_to do |format|
      format.html
      format.js
    end
  end
end
