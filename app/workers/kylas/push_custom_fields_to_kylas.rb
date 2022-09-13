module Kylas
  class PushCustomFieldsToKylas
    include Sidekiq::Worker

    def perform(user_id)
      user = User.where(id: user_id).first
      if user.present?
        User::KYLAS_CUSTOM_FIELDS_ENTITIES.each do |entity|
          Kylas::CreateCustomField.new(user, user, {entity: entity}).call
        end
      end
    end
  end
end