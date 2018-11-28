class SmsesController < ApplicationController
  before_action :authenticate_user!, only: [:index, :show]
  before_action :set_sms, only: :show
  
  def index
    @smses = policy_scope(Sms)
  end
  
  def show
    authorize @sms
  end

  private
   

  def set_sms
    @sms = Sms.find(params[:id])
  end
end
