# frozen_string_literal: true

# DatabaseSeeds::UITemplate.seed CLient.last.id
module DatabaseSeeds
  module UITemplate
    def self.seed(client_id)
      if Template::UITemplate.where(name: '').blank?
        Template::UITemplate.create({ booking_portal_client_id: client_id, subject_class: '', name: '', content: '' })
      end

      Template::UITemplate.where(booking_portal_client_id: client_id).count
    end
  end
end
