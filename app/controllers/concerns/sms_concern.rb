module SmsConcern
  extend ActiveSupport::Concern

  def set_sms
    @sms = Sms.find(params[:id])
  end
end
