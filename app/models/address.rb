class Address
  include Mongoid::Document
  include Mongoid::Timestamps

  field :one_line_address, type: String
  field :address1, type: String
  field :address2, type: String
  field :city, type: String
  field :state, type: String
  field :country, type: String
  field :zip, type: String
  field :address_type, type: String, default: 'work' #TODO: Must be personal, work etc
  field :selldo_id, type: String

  belongs_to :addressable, polymorphic: true, optional: true

  validates :address_type, presence: true
  validate :check_presence

  enable_audit({
    audit_fields: [:city, :state, :country, :address_type, :selldo_id],
    associated_with: ["addressable"]
  })

  def name_in_error
    address_type
  end

  def ui_json
    to_json
  end

  def to_sentence
    return self.one_line_address if self.one_line_address.present?
    str = "#{self.address1}"
    str += " #{self.address2}," if self.address2.present?
    str += " #{self.city}," if self.city.present?
    str += " #{self.state}," if self.state.present?
    str += " #{self.country}," if self.country.present?
    str += " #{self.zip}" if self.zip.present?
    str.strip!
    str.present? ? str : "-"
  end

  def check_presence
    errors.add(:base, 'address is invalid') unless as_json(only: [:address1, :city, :state, :country, :zip]).values.all? || one_line_address.present?
  end
end
