# DatabaseSeeds::EmailTemplates.seed(Client.first.id)
module DatabaseSeeds
  module EmailTemplates
    def self.project_based_email_templates_seed project_id
      project = Project.find project_id
      client_id = project.booking_portal_client_id.to_s
      DatabaseSeeds::EmailTemplates::Scheme.seed(project_id, client_id)
      DatabaseSeeds::EmailTemplates::BookingDetail.seed(project_id, client_id)
      DatabaseSeeds::EmailTemplates::Receipt.seed(project_id, client_id)
      DatabaseSeeds::EmailTemplates::BookingDetailScheme.seed(project_id, client_id)
      DatabaseSeeds::EmailTemplates::UserRequest.seed(project_id, client_id)
      DatabaseSeeds::EmailTemplates::Reminder.project_based_email_templates_seed(project_id, client_id)
      DatabaseSeeds::EmailTemplates::Invoice.seed(project_id, client_id)
    end

    def self.client_based_email_templates_seed client_id
      DatabaseSeeds::EmailTemplates::User.seed(client_id)
      DatabaseSeeds::EmailTemplates::Reminder.client_based_email_templates_seed(client_id)
      Template::EmailTemplate.create!(booking_portal_client_id: client_id, subject_class: "UserKyc", name: "user_kyc_added", subject: "User kyc added <%= self.name %>", content: 'test') if ::Template::EmailTemplate.where(name: "user_kyc_added").blank?
    end

    def self.project_unit_overview
      '<div class="card">
        <div class="card-body">
          <table class="table">
            <tbody>
              <tr>
                <td>
                  <div class="form-group">
                    <label>Name</label>
                    <div>
                      <%= self.name %>
                    </div>
                  </div>
                </td>
                <td>
                  <div class="form-group">
                    <label>Tower</label>
                    <div>
                      <%= self.project_unit.project_tower_name %>
                    </div>
                  </div>
                </td>
                <td>
                  <div class="form-group">
                    <label>Status</label>
                    <div>
                      <%= BookingDetail.human_attribute_name("status.#{self.status}") %>
                    </div>
                  </div>
                </td>
              </tr>
              <tr>
                <td>
                  <div class="form-group">
                    <label>Beds / Baths</label>
                    <div>
                      <%= self.project_unit.bedrooms %> / <%= self.project_unit.bathrooms %>
                    </div>
                  </div>
                </td>
                <td>
                  <div class="form-group">
                    <label>Carpet</label>
                    <div>
                      <%= self.project_unit.carpet %> <%= current_client.area_unit %>
                    </div>
                  </div>
                </td>
                <td>
                  <div class="form-group">
                    <label>Saleable</label>
                    <div>
                      <%= self.project_unit.saleable %> <%= current_client.area_unit %>
                    </div>
                  </div>
                </td>
              </tr>
              <tr>
                <td>
                  <div class="form-group">
                    <label>Effective Rate</label>
                    <div>
                      <%= number_to_indian_currency(self.project_unit.effective_rate) %> <%= current_client.area_unit %>
                    </div>
                  </div>
                </td>
                <td>
                  <div class="form-group">
                    <label>Agreement Price</label>
                    <div>
                      <%= number_to_indian_currency(self.project_unit.agreement_price) %>
                    </div>
                  </div>
                </td>
                <td>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>'
    end
    def self.project_unit_cost_sheet
      '<div class="card">
        <div class="card-body">
          <%= self.project_unit.cost_sheet_template.parsed_content(self) %>
        </div>
      </div>'
    end
    def self.project_unit_payment_schedule
      '<div class="card">
        <div class="card-body">
          <%= self.project_unit.payment_schedule_template.parsed_content(self) %>
        </div>
      </div>'
    end
  end
end


require 'database_seeds/email_templates/booking_detail'
require 'database_seeds/email_templates/receipt'
require 'database_seeds/email_templates/user_request'
require 'database_seeds/email_templates/user'
require 'database_seeds/email_templates/scheme'
require 'database_seeds/email_templates/booking_detail_scheme'
require 'database_seeds/email_templates/reminder'
