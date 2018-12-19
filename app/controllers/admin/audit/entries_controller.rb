class Admin::Audit::EntriesController < ApplicationController
  # GET/admin/audit/entries/:id(.:format)                                           
  def show
    authorize [:admin, Audit::Entry]
    @audit_entries = Audit::Entry.where(audit_id: params[:id])
    respond_to do |format|
      format.html
      format.js
    end
  end
end
