class BookingDetailScheme
  include Mongoid::Document
  include Mongoid::Timestamps
  include InsertionStringMethods
  include SchemeStateMachine

  field :derived_from_scheme_id, type: BSON::ObjectId
  field :status, type: String, default: "draft"
  field :approved_at, type: DateTime

  belongs_to :booking_detail
  belongs_to :approved_by, class_name: "User", optional: true
  belongs_to :booking_portal_client, class_name: "Client"
  embeds_many :payment_adjustments, as: :payables

  def self.derived_scheme_attributes derived_from_scheme_id
    scheme = Scheme.find derived_from_scheme_id
    if scheme.payment_adjustments.present?
      scheme.payment_adjustments.collect do |payment_adjustment|
        attrs = payment_adjustment.clone.attributes
        attrs.delete "_id"
        attrs
      end
    else
      []
    end
  end

  def derived_from_scheme
    Scheme.find self.derived_from_scheme_id
  end

end
