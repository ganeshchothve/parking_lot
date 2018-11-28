class Admin::EmailsController < ApplicationController
  before_action :authenticate_user!, only: [:index, :show]
  before_action :set_email, only: :show

  def index
    @emails = policy_scope([:admin, Email])
  end

  def show
    authorize([:admin, @email])
  end

  private


  def set_email
    @email = Email.find(params[:id])
  end
end
