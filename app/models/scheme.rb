class Scheme
  include Mongoid::Document
  include Mongoid::Timestamps
  include InsertionStringMethods
  include SchemeStateMachine

  field :name, type: String
  field :description, type: String
  field :user_role, type: String
  field :status, type: String, default: "draft"
  field :approved_at, type: DateTime
  field :payment_schedule_template_id, type: BSON::ObjectId
  field :cost_sheet_template_id, type: BSON::ObjectId
  field :default, type: Boolean
  field :can_be_applied_by, type: Array

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
  has_and_belongs_to_many :users

  validates :name, :status, :cost_sheet_template_id, :payment_schedule_template_id, presence: true
  validates :name, uniqueness: {scope: :project_tower_id}
  validates :approved_by, presence: true, if: Proc.new{|scheme| scheme.status == 'approved' && !scheme.default? }
  validate :at_least_one_condition
  validate :project_related

  accepts_nested_attributes_for :payment_adjustments, allow_destroy: true

  default_scope -> {desc(:created_at)}

  def self.available_fields
    ["agreement_price", "all_inclusive_price", "base_rate", "floor_rise"]
  end

  def self.build_criteria params={}
    selector = {}
    if params[:fltrs].present?
      selector[:status] = params[:fltrs][:status] if params[:fltrs][:status].present?
      selector[:can_be_applied_by] = params[:fltrs][:can_be_applied_by] if params[:fltrs][:can_be_applied_by].present?
      selector[:user_role] = params[:fltrs][:user_role] if params[:fltrs][:user_role].present?
      selector[:project_tower_id] = params[:fltrs][:project_tower] if params[:fltrs][:project_tower].present?
    end
    selector[:name] = ::Regexp.new(::Regexp.escape(params[:fltrs][:name]), 'i') if params[:fltrs].present? && params[:fltrs][:name].present? 
    self.where(selector)
  end

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
