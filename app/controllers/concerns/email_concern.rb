module EmailConcern
  extend ActiveSupport::Concern

  def index
    @emails = Email.build_criteria params
    @emails = @emails.order(created_at: :desc).paginate(page: params[:page] || 1, per_page: 15)
  end

  def show
  end

  private


  def set_email
    @email = Email.find(params[:id])
  end

  def set_layout
    return 'mailer' if action_name == "show"
    super
  end
end
