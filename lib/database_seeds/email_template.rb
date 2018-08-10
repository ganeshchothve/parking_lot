module DatabaseSeeds
  module EmailTemplate
    def self.seed client_id
      EmailTemplate.create!(booking_portal_client_id: client_id, subject_class: "UserRequest", name: "receipt_success", subject: "Test", body: '<div class="card w-100">\
          <div class="card-body">\
            <p>Dear {{ user.name }},</p>\
            <p>\
              Welcome to {{ current_project.name }}. Thank you for your payment of {{ total_amount }}. We will contact you shortly to discuss the next round of formalities.\
            </p>\
          </div>\
        </div>\
        <div class="mt-3"></div>.') if ::EmailTemplate.where(name: "receipt_success").blank?
    end
  end
end
