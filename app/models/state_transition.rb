class StateTransition
  include Mongoid::Document
  include Mongoid::Timestamps

  field :status, type: String
  field :enter_time, type: DateTime
  field :exit_time, type: DateTime
  field :comment, type: String
  field :transition_done_by_id, type: String
  field :error_list, type: Array, default: []
  field :queue_number, type: Integer
  field :revisit_queue_number, type: Integer
  field :sitevisit_id, type: BSON::ObjectId

  embedded_in :lead

end
