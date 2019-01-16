class Audit::Entry
  include Mongoid::Document
  field :field_name, type: String
  field :old_value, type: String
  field :new_value, type: String
  belongs_to :record, :foreign_key => "audit_id"
end
