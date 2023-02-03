class Admin::BulkJobsController < ApplicationController
  before_action :authorize_resource
  around_action :apply_policy_scope, only: :index

  def index
    @bulk_jobs = BulkJob.build_criteria params
    @bulk_jobs = @bulk_jobs.paginate(page: params[:page] || 1, per_page: params[:per_page])
    respond_to do |format|
      format.html {}
      format.json {}
    end
  end

  private

  def authorize_resource
    if %w(index).include?params[:action]
      authorize [:admin, BulkJob]
    end
  end

  def apply_policy_scope
    custom_scope = BulkJob.where(BulkJob.user_based_scope(current_user, params))
    BulkJob.with_scope(policy_scope(custom_scope)) do
      yield
    end
  end
end
