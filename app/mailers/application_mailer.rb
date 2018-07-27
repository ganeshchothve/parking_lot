class ApplicationMailer < ActionMailer::Base
  before_action :load_and_store_client, :load_project

  default from: -> {
    client = Client.where(id: RequestStore::Base.get("client_id")).first
    if client.present?
      client.name + " <" + client.notification_email + ">"
    else
      "Notification <no-reply@bookingportal.com>"
    end
  }
  layout 'mailer'
  helper ApplicationHelper

  def load_and_store_client
    @client = Client.first #GENERICTODO: Handle this
    RequestStore::Base.set "client_id", @client.id
  end

  def load_project
    # TODO: for now we are considering one project per client only so loading first client project here
    @project = @client.projects.first if @client.present?
  end
end
