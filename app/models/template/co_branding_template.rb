class Template::CoBrandingTemplate < Template
  
  field :name, type: String

  validates :name, presence: true

  def self.seed(client_id)
    Template::CoBrandingTemplate.create(booking_portal_client_id: client_id, name: 'first_page_co_branding', content: Template::CoBrandingTemplate.default_first_page_co_branding_content)  if Template::CoBrandingTemplate.where(booking_portal_client_id: client_id, name: 'first_page_co_branding').blank?
    Template::CoBrandingTemplate.create(booking_portal_client_id: client_id, name: 'last_page_co_branding', content: Template::CoBrandingTemplate.default_last_page_co_branding_content)  if Template::CoBrandingTemplate.where(booking_portal_client_id: client_id, name: 'last_page_co_branding').blank?
  end

  def self.default_first_page_co_branding_content
    '<div class="card">
      <div class="card-body">
        <div class="row">
          <div class="col-md-4">
            <div class="mb-3">
              <label>Name</label>
              <div>
                <%= self.name %>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>'
  end

  def self.default_last_page_co_branding_content
    '<div class="card">
      <div class="card-body">
        <div class="row">
          <div class="col-md-4">
            <div class="mb-3">
              <label>Name</label>
              <div>
                <%= self.name %>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>'
  end
end