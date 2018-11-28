class EmailsController < ApplicationController
  before_action :authenticate_user!, only: %i[index show]
  before_action :set_email, only: :show

  def index
    @emails = policy_scope(Email)
  end

  def show
    authorize @email
  end

  private

  def set_email
    @email = Email.find(params[:id])
  end
end
