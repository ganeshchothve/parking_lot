class Scheme
  include Mongoid::Document
  include Mongoid::Timestamps
  include InsertionStringMethods

  field :name, type: String
  field :description, type: String
  field :project_unit_id, type: String
  field :user_id, type: String
  field :user_role, type: String
  field :status, type: String, default: "draft"
  field :approved_at, type: DateTime
  field :payment_schedule_template_id, type: BSON::ObjectId
  field :cost_sheet_template_id, type: BSON::ObjectId
  field :default, type: Boolean
  field :can_be_applied_by, type: Array

  enable_audit({
    indexed_fields: [:project_id, :project_tower_id, :project_unit_id, :user_id],
    audit_fields: [:name, :project_unit_id, :user_id, :user_role, :value, :status, :approved_by_id, :created_by_id, :can_be_applied_by],
  })

  embeds_many :payment_adjustments
  belongs_to :project
  belongs_to :project_tower
  belongs_to :approved_by, class_name: "User", optional: true
  belongs_to :created_by, class_name: "User"
  belongs_to :booking_portal_client, class_name: "Client"
  belongs_to :user, class_name: 'User', optional: true

  validates :name, :status, presence: true
  validates :name, uniqueness: {scope: :project_tower_id}
  validates :approved_by, presence: true, if: Proc.new{|scheme| scheme.status == 'approved' && !scheme.default? }
  validate :at_least_one_condition
  validate :project_related
  validate :user_related

  accepts_nested_attributes_for :payment_adjustments

  default_scope -> {desc(:created_at)}

  def self.available_statuses
    [
      {id: "draft", text: "Draft"},
      {id: "approved", text: "Approved"},
      {id: "disabled", text: "Disabled"}
    ]
  end

  def self.build_criteria params={}
    selector = {}
    if params[:fltrs].present?
      if params[:fltrs][:status].present?
        selector[:status] = params[:fltrs][:status]
      end
    end
    selector[:name] = ::Regexp.new(::Regexp.escape(params[:q]), 'i') if params[:q].present?
    self.where(selector)
  end

  def project_unit
    return ProjectUnit.find(self.project_unit_id) if self.project_unit_id.present?
    return nil
  end

  def project_tower
    return ProjectTower.find(self.project_tower_id) if self.project_tower_id.present?
    return nil
  end

  def user
    return User.find(self.user_id) if self.user_id.present?
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


  private
  def at_least_one_condition
    if self.project_id.blank? && self.project_tower_id.blank? && self.project_unit_id.blank? && self.user_id.blank? && self.user_role.blank?
      self.errors.add :base, "At least one condition is required to create a discount"
    end
  end

  def user_related
    if self.user_role.present? && self.user_id.present?
      if self.user.role != self.user_role
        self.errors.add :base, "The chosen user and the role do not match. Set either one"
      end
    end
  end

  def project_related
    if self.project_id.present? && self.project_tower_id.present?
      if self.project_tower.project_id != self.project_id
        self.errors.add :base, "The chosen project and tower do not match. Set either one"
      end
    end
    if self.project_tower_id.present? && self.project_unit_id.present?
      if self.project_unit.project_tower_id != self.project_tower_id
        self.errors.add :base, "The chosen tower and unit do not match. Set either one"
      end
    end
  end
end
