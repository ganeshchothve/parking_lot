class Admin::EmailsController < ApplicationController
  before_action :authenticate_user!, only: %i[index show]
  before_action :set_email, only: :show
  around_action :apply_policy_scope, only: :index
  layout :set_layout

  def index
    @emails = Email.build_criteria params
    authorize([:admin, @emails])
    @emails = @emails.order(created_at: :desc).paginate(page: params[:page] || 1, per_page: 15)
  end

  def show
    authorize([:admin, @email])
  end

  private
  
  def set_email
    @email = Email.find(params[:id])
  end

  def apply_policy_scope
    Email.with_scope(policy_scope([:admin, Email])) do
      yield
    end
  end
  def set_layout
    return 'mailer' if action_name == "show"
    super
  end
end
