class AuditEntry
  include Mongoid::Document
  field :field_name, type: String
  field :old_value, type: String
  field :new_value, type: String
  field :audit_id, type: BSON::ObjectId

  belongs_to :audit_record
end
