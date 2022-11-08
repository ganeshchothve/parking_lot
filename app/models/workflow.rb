class Workflow
  include Mongoid::Document
  include Mongoid::Timestamps
  extend FilterByCriteria

  WORKFLOW_BOOKING_STAGES = %w[blocked booked_tentative booked_confirmed cancelled under_negotiation].freeze
  PRODUCT_AMOUNT_TYPES = %w[agreement_price all_inclusive_price].freeze

  field :stage, type: String

  # flags to trigger workflow events in Kylas
  field :create_product, type: Boolean, default: false
  field :deactivate_product, type: Boolean, default: false
  field :update_product_on_deal, type: Boolean, default: false
  field :product_amount_type, type: String

  has_many :pipelines
  belongs_to :booking_portal_client, class_name: 'Client'

  validates :stage, inclusion: { in: WORKFLOW_BOOKING_STAGES }
  validates :stage, presence: true, uniqueness: { scope: :booking_portal_client_id, message: 'Stage is already present in a workflow' }
  validate :pipelines_for_present_stage
  validate :validate_create_product
  validate :validate_deactivate_product
  validate :validate_update_product_on_deal
  validates :product_amount_type, inclusion: { in: PRODUCT_AMOUNT_TYPES }, allow_blank: true
  validates :product_amount_type, presence: true, if: Proc.new{ |workflow| workflow.create_product? }

  accepts_nested_attributes_for :pipelines, allow_destroy: true

  def pipelines_for_present_stage
    if self.pipelines.size != self.pipelines.map(&:pipeline_id).uniq.size
      errors.add(:base, 'Pipelines cannot be same for same stage')
    end
  end

  def can_create_product?
    booking_portal_client.workflows.where(create_product: true).blank?
  end

  def can_deactivate_product?
    booking_portal_client.workflows.where(deactivate_product: true).blank?
  end

  def can_update_product_on_deal?
    booking_portal_client.workflows.where(update_product_on_deal: true).blank?
  end

  def can_set_product_amount_type?
    create_product && booking_portal_client.workflows.where(product_amount_type: nil).present?
  end

  def validate_create_product
    if create_product && create_product_changed?
      errors.add(:create_product, 'cannot be true for more than one workflow') unless can_create_product?
    end
  end

  def validate_deactivate_product
    if deactivate_product && deactivate_product_changed?
      errors.add(:deactivate_product, 'cannot be true for more than one workflow') unless can_deactivate_product?
    end
  end

  def validate_update_product_on_deal
    if update_product_on_deal && update_product_on_deal_changed?
      errors.add(:update_product_on_deal, 'cannot be true for more than one workflow') unless can_update_product_on_deal?
    end
  end

  def validate_product_amount_type
    if create_product && product_amount_type_changed?
      errors.add(:product_amount_type, 'cannot be set for more than one workflow') unless can_set_product_amount_type?
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