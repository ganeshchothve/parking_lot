class BookingDetailScheme
  include Mongoid::Document
  include Mongoid::Timestamps
  include InsertionStringMethods
  include BookingDetailSchemeStateMachine

  field :derived_from_scheme_id, type: BSON::ObjectId
  field :status, type: String, default: "draft"
  field :approved_at, type: DateTime
  field :payment_schedule_template_id, type: BSON::ObjectId
  field :cost_sheet_template_id, type: BSON::ObjectId

  attr_accessor :created_by_user

  belongs_to :project_unit, class_name: 'ProjectUnit'
  belongs_to :booking_detail, class_name: 'BookingDetail', optional: true
  belongs_to :approved_by, class_name: "User", optional: true
  belongs_to :created_by, class_name: "User"
  belongs_to :booking_portal_client, class_name: "Client"
  embeds_many :payment_adjustments, as: :payables
  accepts_nested_attributes_for :payment_adjustments, allow_destroy: true

  validates :booking_detail_id, presence: true, if: Proc.new{|record| record.status == "approved" }

  def derived_from_scheme
    Scheme.find self.derived_from_scheme_id
  end

  def payment_schedule_template
    Template::PaymentScheduleTemplate.find self.payment_schedule_template_id
  end

  def cost_sheet_template
    Template::CostSheetTemplate.find self.cost_sheet_template_id
  end

  def approver? user
    user.role?('admin') || user.role?('superadmin')
  end

end
