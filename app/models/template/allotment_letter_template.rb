class Template::AllotmentLetterTemplate < Template
  def self.default_content
    '<div class="card w-100">
      <div class="card-body">
        <p>Dear <%= @user.name %>,</p>
        Congratulations!<br/><br/>
        Welcome to the <%= current_project.name %>! You\'re now the proud owner of Unit - <%= self.name %>.<br/><br/>
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
      <div class="card-footer">
        <% if defined?(with_actions) && with_actions == true %>
          <nav class="nav">
            <% if current_user.buyer? && self.user == current_user && ["blocked", "booked_tentative", "booked_confirmed"].include?(self.status) %>
              <% if ProjectUnitPolicy.new(current_user, project_unit).edit? %>
              <%= link_to "Update #{global_labels["user_kycs"]}", edit_admin_project_unit_path(project_unit), class: "modal-remote-form-link nav-link pl-0" %>
              <% end %>
              <% if ReceiptPolicy.new(current_user, self.user.receipts.new(project_unit_id: self.id)).new? %>
                <a href="<%= new_user_receipt_path(project_unit_id: self.id) %>" class="nav-link modal-remote-form-link">
                Pay Remaining Amount
                </a>
              <% end %>
              <% if current_user.user_requests.where(project_unit_id: self.id).ne(status: "resolved").blank? %>
                <a href="<%= new_admin_user_request_path(project_unit_id: self.id) %>" class="nav-link text-danger modal-remote-form-link">Cancel Booking</a>
              <% else %>
                <span class="nav-link unit-cancelled">Cancellation Requested</span>
              <% end %>
            <% elsif current_user.buyer? && self.user == current_user && ["hold"].include?(self.status) %>
              <a href="<%= checkout_user_search_path(current_user.get_search(self.id)) %>" class="nav-link pl-0">
                Book Now
              </a>
            <% end %>
          </nav>
        <% end %>
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
