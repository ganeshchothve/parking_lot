class Lead
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable
  include ApplicationHelper
  include CrmIntegration
  extend FilterByCriteria
  extend ApplicationHelper

  THIRD_PARTY_REFERENCE_IDS = %w(reference_id)

  field :manager_change_reason, type: String
  field :referenced_manager_ids, type: Array, default: []
  field :iris_confirmation, type: Boolean, default: false

  belongs_to :manager, class_name: 'User', optional: true

  belongs_to :user
  belongs_to :project
  has_many :receipts
  has_many :booking_details
  has_many :user_requests
  has_many :user_kycs
  has_many :assets, as: :assetable
  has_many :notes, as: :notable
  has_many :smses, as: :triggered_by, class_name: 'Sms'
  has_many :emails, as: :triggered_by, class_name: 'Email'
  has_many :whatsapps, as: :triggered_by, class_name: 'Whatsapp'
  #has_many :project_units
  #has_and_belongs_to_many :received_emails, class_name: 'Email', inverse_of: :recipients
  #has_and_belongs_to_many :cced_emails, class_name: 'Email', inverse_of: :cc_recipients
  #has_many :received_smses, class_name: 'Sms', inverse_of: :recipient
  #has_many :received_whatsapps, class_name: 'Whatsapp', inverse_of: :recipient

  validates_uniqueness_of :user, scope: :project_id, message: 'already exists'

  delegate :name, :email, :phone, to: :user, prefix: false, allow_nil: true
  delegate :name, to: :project, prefix: true, allow_nil: true


  def is_payment_done?
    receipts.where('$or' => [{ status: { '$in': %w(success clearance_pending) } }, { payment_mode: {'$ne': 'online'}, status: {'$in': %w(pending clearance_pending success)} }]).present?
  end

  def total_amount_paid
    receipts.where(status: 'success').sum(:total_amount)
  end

  def total_balance_pending
    booking_details.in(status: ProjectUnit.booking_stages).sum(&:pending_balance)
  end

  def total_unattached_balance
    receipts.in(status: %w[success clearance_pending]).where(booking_detail_id: nil).sum(:total_amount)
  end

  class << self

    def user_based_scope(user, params = {})
      custom_scope = {}
      case user.role.to_sym
      when :channel_partner
        custom_scope[:'$or'] = [{manager_id: user.id}, {manager_id: nil, referenced_manager_ids: user.id, iris_confirmation: false}]
      when :cp
        custom_scope = { manager_id: { "$in": User.where(role: 'channel_partner', manager_id: user.id).distinct(:id) } }
      when :cp_admin
        cp_ids = User.where(role: 'cp', manager_id: user.id).distinct(:id)
        custom_scope = { manager_id: { "$in": User.where(role: 'channel_partner').in(manager_id: cp_ids).distinct(:id) }  }
      end
      custom_scope = { user_id: params[:user_id] } if params[:user_id].present?
      custom_scope = { user_id: user.id } if user.buyer?
      custom_scope
    end

  end
end
