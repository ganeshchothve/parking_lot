class BookingDetailScheme
  include Mongoid::Document
  include Mongoid::Timestamps
  include InsertionStringMethods
  include BookingDetailSchemeStateMachine

  # field :derived_from_scheme_id, type: BSON::ObjectId
  field :status, type: String, default: "draft"
  field :approved_at, type: DateTime

  attr_accessor :created_by_user

  belongs_to :project_unit, class_name: 'ProjectUnit'
  belongs_to :booking_detail, class_name: 'BookingDetail', optional: true
  belongs_to :user, optional: true
  belongs_to :approved_by, class_name: "User", optional: true
  belongs_to :created_by, class_name: "User"
  belongs_to :booking_portal_client, class_name: "Client"
  belongs_to :derived_from_scheme, class_name: 'Scheme'
  belongs_to :payment_schedule_template, class_name: 'Template::PaymentScheduleTemplate', optional: Rails.env.test?
  belongs_to :cost_sheet_template, class_name: 'Template::CostSheetTemplate', optional: Rails.env.test?

  embeds_many :payment_adjustments, as: :payables

  accepts_nested_attributes_for :payment_adjustments, allow_destroy: true

  validates :booking_detail_id, presence: true, if: Proc.new{|record| record.status == "approved" }

  delegate :project_tower_id, to: :derived_from_scheme, prefix: false, allow_nil: true

  def editable_payment_adjustments
    self.payment_adjustments.in(editable: [true, nil])
  end

  def non_editable_payment_adjustments
    self.payment_adjustments.where(editable: false)
  end

  def approver? user
    user.role?('admin') || user.role?('superadmin')
  end

end
