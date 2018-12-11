class Admin::SmsesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_sms, only: :show
  around_action :apply_policy_scope, only: :index

  def index
    @smses = Sms.build_criteria params
    authorize([:admin, @smses])
    @smses = @smses.order(created_at: :desc).paginate(page: params[:page] || 1, per_page: 15)
  end

  def show
    authorize([:admin, @sms])
  end

  private


  def set_sms
    @sms = Sms.find(params[:id])
  end

  def apply_policy_scope
    Sms.with_scope(policy_scope([:admin, Sms])) do
      yield
    end
  end
end
