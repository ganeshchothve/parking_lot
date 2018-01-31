class Address
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :addressable, polymorphic: true

  field :address1, type: String
  field :address2, type: String
  field :city, type: String
  field :state, type: String
  field :country, type: String
  field :country_code, type: String
  field :zip, type: String
  field :primary, type: Boolean, default: false
  field :address_type, type: String #TODO: Must be personal, work etc
  field :selldo_id, type: String

  def ui_json
    to_json
  end

  def to_sentence
    return "#{self.address1}  #{self.address2},#{self.city},#{self.state},#{self.country},#{self.zip}"
  end
end
