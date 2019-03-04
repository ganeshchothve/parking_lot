module EmailConcern
  extend ActiveSupport::Concern

  #
  # This index action for Admin, users where they can view all the emails sent.
  # Admin can  view all the emails and user can view the emails sent to them.
  #
  # @return [{},{}] records with array of Hashes.
  #
  def index
    @emails = Email.build_criteria params
    @emails = @emails.order(created_at: :desc).paginate(page: params[:page] || 1, per_page: params[:per_page])
  end

  #
  # This show action for Admin, users where they can view the details of a particular email.
  #
  # @return [{}] record with array of Hashes.
  #
  def show; end

  private

  def set_email
    @email = Email.find(params[:id])
  end

  def set_layout
    return 'mailer' if action_name == 'show'
    super
  end
end
