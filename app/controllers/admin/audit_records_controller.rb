class Admin::AuditRecordsController < ApplicationController

  def index
  	@audits=AuditRecord.all.build_criteria(params).paginate(page: params[:page] || 1, per_page: 15)
    authorize(current_user)
  end

  def show
  	@audit_entries=AuditEntry.where(audit_id: params[:id])
    authorize(current_user)
  	respond_to do |format|
    	format.html
    	format.js
  	end
  end
end
