module Kylas
  class Api::ExecuteWorker
    include Sidekiq::Worker
    sidekiq_options queue: 'event'

    def perform(user_id, api_id, klass, model_id, payload={})
      api = Crm::Api.where(id: api_id).first
      user = User.where(id: user_id).first
      model = Object.const_get(klass)&.where(id: model_id).first
      if model.present? && api.present?
        model.event_payload = (payload.present? ? payload : {})
        api.execute(model, user)
      end
    end
  end
end
  