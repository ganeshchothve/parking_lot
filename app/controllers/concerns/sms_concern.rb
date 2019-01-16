module SmsConcern
  extend ActiveSupport::Concern

  #
  # This index action for Admin, users where they can view all the smses sent.
  # Admin can  view all the smses and user can view the sms sent to them.
  #
  # @return [{},{}] records with array of Hashes.
  #
  def index
    @smses = Sms.build_criteria params
    @smses = @smses.order(created_at: :desc).paginate(page: params[:page] || 1, per_page: params[:per_page])
  end

  #
  # This show action for Admin, users where they can view the details of a particular sms.
  #
  # @return [{}] record with array of Hashes.
  #
  def show
  end

  private

  def set_sms
    @sms = Sms.find(params[:id])
  end
end
