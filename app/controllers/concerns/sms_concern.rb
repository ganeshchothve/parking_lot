module SmsConcern
  extend ActiveSupport::Concern

  def index
    @smses = Sms.build_criteria params
    @smses = @smses.order(created_at: :desc).paginate(page: params[:page] || 1, per_page: 15)
  end

  def show
  end

  private

  def set_sms
    @sms = Sms.find(params[:id])
  end
end
