module Crm
  class Api::ExecuteWorker
    def perform(method, klass, model_id, event=nil, payload={}, crm_base_id=nil)
      model = Object.const_get(klass)&.where(id: model_id).first
      if model.present?
        api_attrs = {resource_class: klass, is_active: true}
        api_attrs[:event] = event if event.present?
        api_attrs[:base_id] = crm_base_id if crm_base_id.present?
        model.event_payload = (payload.present? ? payload : {})

        Object.const_get("Crm::Api::#{method.classify}").where(api_attrs).each do |api|
          api.execute(model)
        end
      end
    end
  end
end
