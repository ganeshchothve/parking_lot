class BookingDetailScheme
  include Mongoid::Document
  include Mongoid::Timestamps
  include InsertionStringMethods
  include SchemeStateMachine

  field :derived_from_scheme_id, type: BSON::ObjectId
  field :status, type: String, default: "draft"
  field :approved_at, type: DateTime
  field :payment_schedule_template_id, type: BSON::ObjectId
  field :cost_sheet_template_id, type: BSON::ObjectId

  attr_accessor :created_by_user

  belongs_to :booking_detail, class_name: 'BookingDetail'
  belongs_to :approved_by, class_name: "User", optional: true
  belongs_to :created_by, class_name: "User"
  belongs_to :booking_portal_client, class_name: "Client"
  embeds_many :payment_adjustments, as: :payables
  accepts_nested_attributes_for :payment_adjustments, allow_destroy: true

  def self.derived_scheme_attributes derived_from_scheme_id
    scheme = Scheme.find derived_from_scheme_id
    derived_scheme_id_attribute = {derived_from_scheme_id: (scheme.is_a?(BookingDetailScheme) ? scheme.derived_from_scheme_id : nil)}
    if scheme.payment_adjustments.present?
      payment_adjustments_attributes = scheme.payment_adjustments.collect do |payment_adjustment|
        attrs = payment_adjustment.clone.attributes
        attrs.delete "_id"
        attrs
      end
      {payment_adjustments_attributes: payment_adjustments_attributes}.merge(derived_scheme_id_attribute)
    else
      derived_scheme_id_attribute
    end
  end

  def derived_from_scheme
    Scheme.find self.derived_from_scheme_id
  end

end
