module DatabaseSeeds
  module EmailTemplates
    def self.seed client_id

      DatabaseSeeds::EmailTemplates::Receipt.seed client_id
      DatabaseSeeds::EmailTemplates::ProjectUnit.seed client_id
      DatabaseSeeds::EmailTemplates::UserRequest.seed client_id
      DatabaseSeeds::EmailTemplates::Discount.seed client_id

      Template::EmailTemplate.create!(booking_portal_client_id: client_id, subject_class: "UserKyc", name: "user_kyc_added", subject: "User kyc added <%= self.name %>", content: 'test') if ::Template::EmailTemplate.where(name: "user_kyc_added").blank?
    end

    def self.project_unit_overview
      '<div class="card">
        <div class="card-body">
          <div class="row">
            <div class="col-md-4">
              <div class="form-group">
                <label>Name</label>
                <div>
                  <%= self.name %>
                </div>
              </div>
            </div>
            <div class="col-md-4">
              <div class="form-group">
                <label>Tower</label>
                <div>
                  <%= self.project_tower_name %>
                </div>
              </div>
            </div>
            <div class="col-md-4">
              <div class="form-group">
                <label>Status</label>
                <div>
                  <%= ProjectUnit.available_statuses.find{|x| x[:id] == self.status}[:text] %>
                </div>
              </div>
            </div>
          </div>
          <div class="row">
            <div class="col-md-4">
              <div class="form-group">
                <label>Beds / Baths</label>
                <div>
                  <%= self.bedrooms %> / <%= self.bathrooms %>
                </div>
              </div>
            </div>
            <div class="col-md-4">
              <div class="form-group">
                <label>Carpet</label>
                <div>
                  <%= self.carpet %> <%= current_client.area_unit %>
                </div>
              </div>
            </div>
            <div class="col-md-4">
              <div class="form-group">
                <label>Saleable</label>
                <div>
                  <%= self.saleable %> <%= current_client.area_unit %>
                </div>
              </div>
            </div>
          </div>
          <div class="row">
            <div class="col-md-4">
              <div class="form-group">
                <label>Effective Rate</label>
                <div>
                  <%= number_to_indian_currency(self.effective_rate) %> <%= current_client.area_unit %>
                </div>
              </div>
            </div>
            <div class="col-md-4">
              <div class="form-group">
                <label>Agreement Price</label>
                <div>
                  <%= number_to_indian_currency(self.agreement_price) %>
                </div>
              </div>
            </div>
          </div>
        </div>'
    end
    def self.project_unit_cost_sheet
      '<div class="card">
        <div class="card-body">
          <%= self.cost_sheet_template.parsed_content(self) %>
        </div>
      </div>'
    end
    def self.project_unit_payment_schedule
      '<div class="card">
        <div class="card-body">
          <%= self.payment_schedule_template.parsed_content(self) %>
        </div>
      </div>'
    end
  end
end


require 'database_seeds/email_templates/project_unit'
require 'database_seeds/email_templates/receipt'
require 'database_seeds/email_templates/user_request'
require 'database_seeds/email_templates/discount'
