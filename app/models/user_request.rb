class UserRequest
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable
  include InsertionStringMethods
  include UserRequestStateMachine
  extend FilterByCriteria
  extend ApplicationHelper
  extend DocumentsConcern

  STATUS = %w[pending processing resolved rejected failed]
  # Add different types of documents which are uploaded on user_request
  DOCUMENT_TYPES = []

  field :status, type: String, default: 'pending'
  field :resolved_at, type: DateTime
  field :reason_for_failure, type: String, default: ''

  # belongs_to :booking_detail
  # belongs_to :receipt, optional: true
  belongs_to :booking_portal_client, class_name: 'Client'
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
      project_ids = (params[:current_project_id].present? ? [params[:current_project_id]] : user.project_ids)
      if params[:lead_id].blank? && !user.buyer?
        if user.role.in?(%w(cp_owner channel_partner))
          custom_scope = { user_id: user.id }
        elsif user.role.in?(%w(admin))
          custom_scope = { }
        elsif user.role.in?(%w(superadmin))
          custom_scope = { }
        #elsif user.role?('cp')
        #  channel_partner_ids = User.where(role: 'channel_partner').where(manager_id: user.id).distinct(:id)
        #  custom_scope = { '$or': [{ user_id: { "$in": channel_partner_ids } }, {user_id: user.id}] }
        #elsif user.role?('cp_admin')
        #  cp_ids = User.where(role: 'cp').where(manager_id: user.id).distinct(:id)
        #  channel_partner_ids = User.where(role: 'channel_partner').in(manager_id: cp_ids).distinct(:id)
        #  custom_scope = { '$or': [{ user_id: { "$in": channel_partner_ids } }, {user_id: user.id}] }
        end
      end

      custom_scope = { lead_id: params[:lead_id] } if params[:lead_id].present?
      custom_scope = { user_id: user.id, lead_id: user.selected_lead_id } if user.buyer?

      custom_scope[:requestable_id] = params[:requestable_id] if params[:requestable_id].present?
      custom_scope[:_type] = 'UserRequest::General' unless user.booking_portal_client.enable_actual_inventory?(user)

      if !user.role.in?(User::ALL_PROJECT_ACCESS) || params[:current_project_id].present?
        custom_scope.merge!({project_id: { "$in": project_ids } })
      end
      custom_scope.merge!({booking_portal_client_id: user.booking_portal_client.id})
      custom_scope
    end
  end
end
