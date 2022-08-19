class Workflow
  include Mongoid::Document
  include Mongoid::Timestamps
  extend FilterByCriteria

  WORKFLOW_BOOKING_STAGES = %w[blocked booked_tentative booked_confirmed cancelled]

  field :stage, type: String

  # flags to trigger workflow events in Kylas
  field :create_product, type: Boolean, default: false
  field :deactivate_product, type: Boolean, default: false
  field :update_product_on_deal, type: Boolean, default: false

  has_many :pipelines
  belongs_to :booking_portal_client, class_name: 'Client'

  validates :stage, inclusion: { in: WORKFLOW_BOOKING_STAGES }
  validates :stage, presence: true, uniqueness: { scope: :booking_portal_client_id, message: 'Stage is already present in a workflow' }
  validate :pipelines_for_present_stage

  accepts_nested_attributes_for :pipelines, allow_destroy: true

  def pipelines_for_present_stage
    if self.pipelines.size != self.pipelines.map(&:pipeline_id).uniq.size
      errors.add(:base, 'Pipelines cannot be same for same stage')
    end
  end
  class << self
    def user_based_scope user, params={}
      custom_scope = {}
      if user.role.in?(User::KYLAS_MARKETPALCE_USERS)
        custom_scope = { booking_portal_client_id: user.booking_portal_client.id }
      elsif user.role.in?(%w(superadmin))
        custom_scope = { booking_portal_client_id: user.selected_client_id }
      end
      custom_scope
    end
  end
end