class Admin::Audit::EntriesController < ApplicationController
  def show
    authorize [:admin, Audit::Entry]
    @audit_entries = AuditEntry.where(audit_id: params[:id])
    respond_to do |format|
      format.html
      format.js
    end
  end
end
