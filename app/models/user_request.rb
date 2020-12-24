class UserRequest
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable
  include InsertionStringMethods
  include UserRequestStateMachine
  extend FilterByCriteria

  STATUS = %w[pending processing resolved rejected failed]
  # Add different types of documents which are uploaded on user_request
  DOCUMENT_TYPES = []

  field :status, type: String, default: 'pending'
  field :resolved_at, type: DateTime
  field :reason_for_failure, type: String, default: ''

  # belongs_to :booking_detail
  # belongs_to :receipt, optional: true
  belongs_to :requestable, polymorphic: true, optional: true
  belongs_to :lead, optional: true
  belongs_to :user
  belongs_to :project, optional: true
  belongs_to :resolved_by, class_name: 'User', optional: true
  belongs_to :created_by, class_name: 'User'
  has_many :assets, as: :assetable
  has_many :notes, as: :notable

  validates :user_id, presence: true
  validates :lead_id, :project_id, presence: true, if: proc { |user_request| user_request.user_id.present? && user_request.user.buyer? }
  validates :resolved_by, presence: true, if: proc { |user_request| user_request.status == 'resolved' }

  accepts_nested_attributes_for :notes
  scope :filter_by_project_id, ->(project_id){ where(project_id: project_id) }
  scope :filter_by_user_id, ->(user_id){ where(user_id: user_id)}
  scope :filter_by_lead_id, ->(lead_id){ where(lead_id: lead_id)}
  scope :filter_by__type, ->(request_type){ where(_type: /#{request_type}/i)}
  scope :filter_by_status, ->(_status){ where(status: _status) }
  scope :filter_by_requestable_type, ->(requestable_type){ where(requestable_type: requestable_type) }
  scope :filter_by_requestable, ->(requestable_id){ where(requestable_id: requestable_id) }
  scope :filter_by_booking_detail_id, ->(requestable_id){ where(requestable_id: requestable_id) }
  scope :filter_by_receipt_id, ->(requestable_id){ where(requestable_id: requestable_id) }
  default_scope -> { desc(:created_at) }

  delegate :project_unit, to: :requestable, prefix: false, allow_nil: true
  delegate :name, to: :project, prefix: true, allow_nil: true

  # TODO: on create send email to CRM team

  class << self
    def user_based_scope(user, params = {})

      custom_scope = {}
      if params[:lead_id].blank? && !user.buyer?
        if user.role?('channel_partner')
          custom_scope = { '$or': [{lead_id: { "$in": Lead.where(referenced_manager_ids: user.id).distinct(:id) }}, {user_id: user.id}] }
        elsif user.role?('cp_admin')
          custom_scope = { lead_id: { "$in": Lead.nin(manager_id: [nil, '']).distinct(:id) } }
        elsif user.role?('cp')
          channel_partner_ids = User.where(role: 'channel_partner').where(manager_id: user.id).distinct(:id)
          custom_scope = { lead_id: { "$in": Lead.in(referenced_manager_ids: channel_partner_ids).distinct(:id) } }
        end
      end

      custom_scope = { lead_id: params[:lead_id] } if params[:lead_id].present?
      custom_scope = { user_id: user.id } if user.buyer?

      custom_scope[:booking_detail_id] = params[:booking_detail_id] if params[:booking_detail_id].present?
      custom_scope
    end
  end
end
