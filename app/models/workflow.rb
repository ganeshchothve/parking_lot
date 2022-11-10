class Workflow
  include Mongoid::Document
  include Mongoid::Timestamps
  extend FilterByCriteria

  WORKFLOW_BOOKING_STAGES = ["hold", "blocked", "booked_tentative", "booked_confirmed", "under_negotiation", "scheme_rejected", "scheme_approved",  "swapped", "swap_rejected", "cancelled", "cancellation_rejected"].freeze
  PRODUCT_AMOUNT_TYPES = %w[agreement_price all_inclusive_price].freeze

  field :stage, type: String

  # flags to trigger workflow events in Kylas
  field :create_product, type: Boolean, default: false
  field :deactivate_product, type: Boolean, default: false
  field :update_product_on_deal, type: Boolean, default: false
  field :product_amount_type, type: String
  field :is_active, type: Boolean, default: true

  has_many :pipelines, dependent: :destroy
  belongs_to :booking_portal_client, class_name: 'Client'

  validates :stage, inclusion: { in: WORKFLOW_BOOKING_STAGES }
  validates :stage, presence: true, uniqueness: { scope: :booking_portal_client_id, message: 'Stage is already present in a workflow' }
  validate :pipelines_for_present_stage
  validate :validate_create_product
  validate :validate_deactivate_product
  validate :validate_update_product_on_deal
  validate :validate_product_amount_type
  validates :product_amount_type, inclusion: { in: PRODUCT_AMOUNT_TYPES }, allow_blank: true
  validates :product_amount_type, presence: true, if: Proc.new{ |workflow| workflow.create_product? }

  accepts_nested_attributes_for :pipelines, allow_destroy: true

  def pipelines_for_present_stage
    if self.pipelines.size != self.pipelines.map(&:pipeline_id).uniq.size
      errors.add(:base, 'Pipelines cannot be same for same stage')
    end
  end

  def can_create_product?
    booking_portal_client.workflows.ne(id: self.id).where(create_product: true).blank?
  end
  
  def can_set_product_amount_type?
    can_create_product?
  end

  def can_update_product_on_deal?
    booking_portal_client.workflows.ne(id:self.id).where(update_product_on_deal: true).blank?
  end

  def can_deactivate_product?
    booking_portal_client.workflows.ne(id:self.id).where(deactivate_product: true).blank?
  end

  def validate_create_product
    if create_product && !can_create_product?
      errors.add(:create_product, 'setting cannot be true for more than one workflow')
    end
  end

  def validate_product_amount_type
    if !create_product && product_amount_type.present?
      errors.add(:create_product, 'setting must be on for Product Price')
    end
    if create_product && !can_set_product_amount_type?
      errors.add(:product_amount_type, 'setting cannot be set for more than one workflow')
    end
  end

  def validate_update_product_on_deal
    if update_product_on_deal && !create_product
      errors.add(:create_product, 'setting must be on for Update the product on Deal')
    end
    if update_product_on_deal && !can_update_product_on_deal?
      errors.add(:update_product_on_deal, 'setting cannot be true for more than one workflow')
    end
  end

  def validate_deactivate_product
    if deactivate_product && !update_product_on_deal
      errors.add(:update_product_on_deal, 'setting must be on for deactivate product')
    end
    if deactivate_product && !can_deactivate_product?
      errors.add(:deactivate_product, 'setting cannot be true for more than one workflow')
    end
  end

  def get_product_price
    if product_amount_type.present?
      if product_amount_type == 'agreement_price'
        "agreement_price"
      else
        "calculate_all_inclusive_price"
      end
    end
  end

  class << self
    def user_based_scope user, params={}
      custom_scope = {}
      if user.role.in?(%w(admin))
        custom_scope = {  }
      elsif user.role.in?(%w(superadmin))
        custom_scope = {  }
      end
      custom_scope.merge!({booking_portal_client_id: user.booking_portal_client.id})
      custom_scope
    end
  end
end