class Template::AllotmentLetterTemplate < Template
  def self.default_content
    '<div class="card w-100">
      <div class="card-body">
        <p>Dear <%= self.user.name %>,</p>
        Congratulations!<br/><br/>
        Welcome to the <%= project_name %>! You\'re now the proud owner of Unit - <%= self.name %>.<br/><br/>
        Our executives will be in touch regarding agreement formalities.
      </div>
    </div>
    <div class="mt-3"></div>
    <div class="card">
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
      </div>
    </div>
    <div class="mt-3"></div>
    <div class="card">
      <div class="card-body">
        <%= self.cost_sheet_template.parsed_content(self) %>
      </div>
    </div>
    <div class="mt-3"></div>
    <div class="card">
      <div class="card-body">
        <%= self.payment_schedule_template.parsed_content(self) %>
      </div>
    </div>'
  end
end