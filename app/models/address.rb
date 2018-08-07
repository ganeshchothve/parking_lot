class Address
  include Mongoid::Document
  include Mongoid::Timestamps

  field :address1, type: String
  field :address2, type: String
  field :city, type: String
  field :state, type: String
  field :country, type: String
  field :zip, type: String
  field :address_type, type: String #TODO: Must be personal, work etc
  field :selldo_id, type: String

  belongs_to :addressable, polymorphic: true, optional: true

  enable_audit({
    audit_fields: [:city, :state, :country, :address_type, :selldo_id],
    associated_with: ["addressable"]
  })

  def ui_json
    to_json
  end

  def to_sentence
    return "#{self.address1} #{self.address2}, #{self.city}, #{self.state}, #{self.country}, #{self.zip}"
  end
end
