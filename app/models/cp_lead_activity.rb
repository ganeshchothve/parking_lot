class CpLeadActivity
  include Mongoid::Document
  include Mongoid::Timestamps

  field :registered_at, type: Date
  field :count_status, type: String
  field :lead_status, type: String
  field :expiry_date, type: Date

  belongs_to :user
  belongs_to :lead
end
