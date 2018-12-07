class Admin::EmailsController < ApplicationController
  include EmailConcern
  before_action :authenticate_user!
  before_action :set_email, only: :show #set_email written in EmailConcern
  around_action :apply_policy_scope, only: :index

  def index
    @emails = Email.build_criteria params
    authorize([:admin, @emails])
    @emails = @emails.order(created_at: :desc).paginate(page: params[:page] || 1, per_page: 15)
  end

  def show
    authorize([:admin, @email])
  end

  private


  def apply_policy_scope
    Email.with_scope(policy_scope([:admin, Email])) do
      yield
    end
  end
end

