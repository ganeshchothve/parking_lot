class Template::AllotmentLetterTemplate < Template
  field :name, type: String, default: 'allotment_letter'

  def self.seed(project_id, client_id)
    Template::AllotmentLetterTemplate.create(booking_portal_client_id: client_id, project_id: project_id, name: 'allotment_letter', content: Template::AllotmentLetterTemplate.default_content)  if Template::AllotmentLetterTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: 'allotment_letter').blank?
  end

  def self.default_content
    '<div class="card w-100">
      <div class="card-body">
        <p>Dear <%= @booking_detail.user.name %>,</p>
        Congratulations!<br/><br/>
        Welcome to the <%= @booking_detail.project.name %>! You\'re now the proud owner of Unit - <%= (@booking_detail.name || @booking_detail.booking_project_unit_name)  %>.<br/><br/>
        Our executives will be in touch regarding agreement formalities.
      </div>
    </div>
    <div class="mt-3"></div>
    <div class="card">
      <div class="card-body">
        <div class="row">
          <div class="col-md-4">
            <div class="mb-3">
              <label>Name</label>
              <div>
                <%= @booking_detail.name %>
              </div>
            </div>
          </div>
          <div class="col-md-4">
            <div class="mb-3">
              <label>Tower</label>
              <div>
                <%= @booking_detail.try(:project_unit).try(:project_tower_name) || @booking_detail.try(:project_tower_name) %>
              </div>
            </div>
          </div>
          <div class="col-md-4">
            <div class="mb-3">
              <label>Status</label>
              <div>
                <%= BookingDetail.human_attribute_name("status.#{@booking_detail.status}") %>
              </div>
            </div>
          </div>
        </div>
        <div class="row">
          <div class="col-md-4">
            <div class="mb-3">
              <label>Beds / Baths</label>
              <div>
                <%= @booking_detail.try(:project_unit).try(:bedrooms) || (@booking_detail.try(:project_unit_configuration)) %> / <%= @booking_detail.try(:project_unit).try(:bathrooms) %>
              </div>
            </div>
          </div>
          <div class="col-md-4">
            <div class="mb-3">
              <label>Carpet</label>
              <div>
                <%= @booking_detail.project_unit.try(:carpet) %> <%= @booking_detail.booking_portal_client.try(:area_unit) %>
              </div>
            </div>
          </div>
          <div class="col-md-4">
            <div class="mb-3">
              <label>Saleable</label>
              <div>
                <%= @booking_detail.project_unit.try(:saleable) %> <%= @booking_detail.booking_portal_client.try(:area_unit) %>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>'
  end
end
