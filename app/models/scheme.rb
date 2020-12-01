class Scheme
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable
  include InsertionStringMethods
  include SchemeStateMachine
  extend FilterByCriteria

  FIELDS = %w[agreement_price all_inclusive_price base_rate floor_rise]

  field :name, type: String
  field :description, type: String
  field :user_role, type: String
  field :status, type: String, default: "draft"
  field :approved_at, type: DateTime
  field :payment_schedule_template_id, type: BSON::ObjectId
  field :cost_sheet_template_id, type: BSON::ObjectId
  field :default, type: Boolean
  field :can_be_applied_by, type: Array

  scope :filter_by_name, ->(name) { where(name: ::Regexp.new(::Regexp.escape(name), 'i')) }
  scope :filter_by_can_be_applied_by, ->(user_role) do
    where({ '$and' => ['$or' => [{ can_be_applied_by: nil },{ can_be_applied_by: [] },{ can_be_applied_by: user_role }, {can_be_applied_by: ['']} ] ] })
  end
  scope :filter_by_can_be_applied_by_role, ->(role) { where({ '$and' => [{ can_be_applied_by: role }] }) }
  scope :filter_by_user_role, ->(user_role) do
    where({ '$and' => ['$or' => [{ user_role: nil },{ user_role: [] },{ user_role: user_role },{user_role: '' } ] ] })
  end
  scope :filter_by_user_id, ->(user_id) do
    where({ '$and' => ['$or' => [{ user_ids: nil },{ user_ids: [] },{ user_ids: user_id }, {user_ids: [''] } ] ] })
  end
  scope :filter_by_default_for_user_id, ->(user_id) do
    where({ '$and' => ['$or' => [{ default_for_user_ids: nil }, { default_for_user_ids: [] }, { default_for_user_ids: [''] }, { default_for_user_ids: user_id }]] })
  end
  scope :filter_by_status, ->(status) { where(status: status) }
  scope :filter_by_project_id, ->(project_id) { where(project_id: project_id) }
  scope :filter_by_project_tower_id, ->(project_tower_id) { where(project_tower_id: project_tower_id) }

  enable_audit({
    indexed_fields: [:project_id, :project_tower_id],
    audit_fields: [:name, :user_role, :value, :status, :approved_by_id, :created_by_id, :can_be_applied_by],
  })

  embeds_many :payment_adjustments, as: :payable
  belongs_to :project
  belongs_to :project_tower
  belongs_to :approved_by, class_name: "User", optional: true
  belongs_to :created_by, class_name: "User"
  belongs_to :booking_portal_client, class_name: "Client"
  has_many :booking_detail_schemes, foreign_key: :derived_from_scheme_id
  has_and_belongs_to_many :users
  has_and_belongs_to_many :default_for_users, class_name: 'User'

  validates :name, :status, :cost_sheet_template_id, :payment_schedule_template_id, presence: true
  validates :name, uniqueness: {scope: :project_tower_id}
  validates :approved_by, presence: true, if: Proc.new{|scheme| scheme.status == 'approved' && !scheme.default? }
  validate :at_least_one_condition
  validate :project_related

  accepts_nested_attributes_for :payment_adjustments, allow_destroy: true

  default_scope -> {desc(:created_at)}

  delegate :name, to: :created_by, prefix: true, allow_nil: true
  delegate :name, to: :approved_by, prefix: true, allow_nil: true

  def project_tower
    return ProjectTower.find(self.project_tower_id) if self.project_tower_id.present?
    return nil
  end

  def payment_schedule_template
    Template::PaymentScheduleTemplate.find self.payment_schedule_template_id
  end

  def cost_sheet_template
    Template::CostSheetTemplate.find self.cost_sheet_template_id
  end

  def get key
    payment_adjustment = self.payment_adjustments.where(key: key).first
    if payment_adjustment.present?
      payment_adjustment.calculate
    else
      0
    end
  end

  def approver? user
    user.role?('admin') || user.role?('superadmin')
  end

  def booking_details
    BookingDetail.in(_id: self.booking_detail_schemes.distinct(:booking_detail_id))
  end

  private
  def at_least_one_condition
    if self.project_id.blank? && self.project_tower_id.blank? && self.user_role.blank?
      self.errors.add :base, "At least one condition is required to create a scheme"
    end
  end

  def project_related
    if self.project_id.present? && self.project_tower_id.present?
      if self.project_tower.project_id != self.project_id
        self.errors.add :base, "The chosen project and tower do not match. Set either one"
      end
    end
  end
end
