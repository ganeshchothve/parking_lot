class UserRequest
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable
  include InsertionStringMethods
  include UserRequestStateMachine
  extend FilterByCriteria

  STATUS = %w[pending processing resolved rejected failed]

  field :status, type: String # default: 'pending'
  field :resolved_at, type: DateTime
  field :reason_for_failure, type: String, default: ''

  # belongs_to :booking_detail
  # belongs_to :receipt, optional: true
  belongs_to :requestable, polymorphic: true
  belongs_to :user
  belongs_to :resolved_by, class_name: 'User', optional: true
  belongs_to :created_by, class_name: 'User'
  has_many :assets, as: :assetable
  has_many :notes, as: :notable

  validates :user_id, :requestable_id, :requestable_type, presence: true
  validates :resolved_by, presence: true, if: proc { |user_request| user_request.status == 'resolved' }

  validates :status, inclusion: { in: STATUS }
  validates :reason_for_failure, presence: true, if: proc { |record| record.rejected? }

  validates_uniqueness_of :requestable_id, scope: [:requestable_type, :status], if: proc{|record| record.pending? }

  accepts_nested_attributes_for :notes
  scope :filter_by_user, ->(user_id){ where(user_id: user_id)}
  scope :filter_by__type, ->(request_type){ where(_type: /#{request_type}/i)}
  scope :filter_by_status, ->(_status){ where(status: _status) }
  scope :filter_by_requestable_type, ->(requestable_type){ where(requestable_type: requestable_type) }
  scope :filter_by_requestable, ->(requestable_id){ where(requestable_id: requestable_id) }
  scope :filter_by_booking_detail_id, ->(requestable_id){ where(requestable_id: requestable_id) }
  scope :filter_by_receipt_id, ->(requestable_id){ where(requestable_id: requestable_id) }
  default_scope -> { desc(:created_at) }

  delegate :project_unit, to: :requestable, prefix: false, allow_nil: true

  # TODO: on create send email to CRM team

  class << self
    def user_based_scope(user, params = {})

      custom_scope = {}
      if params[:user_id].blank? && !user.buyer?
        if user.role?('channel_partner')
          custom_scope = { user_id: { "$in": User.where(referenced_manager_ids: user.id).distinct(:id) } }
        elsif user.role?('cp_admin')
          custom_scope = { user_id: { "$in": User.where(role: 'user').nin(manager_id: [nil, '']).distinct(:id) } }
        elsif user.role?('cp')
          channel_partner_ids = User.where(role: 'channel_partner').where(manager_id: user.id).distinct(:id)
          custom_scope = { user_id: { "$in": User.in(referenced_manager_ids: channel_partner_ids).distinct(:id) } }
        end
      end

      custom_scope = { user_id: params[:user_id] } if params[:user_id].present?
      custom_scope = { user_id: user.id } if user.buyer?

      custom_scope[:booking_detail_id] = params[:booking_detail_id] if params[:booking_detail_id].present?
      custom_scope
    end
  end
end
