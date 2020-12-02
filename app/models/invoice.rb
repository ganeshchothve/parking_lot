class Invoice
  include Mongoid::Document
  include Mongoid::Timestamps
  include InsertionStringMethods
  include InvoiceStateMachine
  extend FilterByCriteria

  field :amount, type: Float, default: 0.0
  field :status, type: String, default: 'draft'
  #field :registration_status, type: String
  field :raised_date, type: DateTime
  field :processing_date, type: DateTime
  field :approved_date, type: DateTime
  field :cheque_handover_date, type: Date
  field :rejection_reason, type: String
  field :comments, type: String
  field :ladder_id, type: BSON::ObjectId
  field :ladder_stage, type: Integer
  field :net_amount, type: Float

  belongs_to :project
  belongs_to :booking_detail
  belongs_to :incentive_scheme
  belongs_to :manager, class_name: 'User'
  has_one :receipt
  has_one :incentive_deduction

  validates :ladder_id, :ladder_stage, presence: true
  validates :comments, presence: true, if: :rejected?
  validates :booking_detail_id, uniqueness: { scope: [:incentive_scheme_id, :ladder_id] }
  validates :amount, numericality: { greater_than: 0 }
  validates :net_amount, numericality: { greater_than: 0 }, if: :approved?

  scope :filter_by_status, ->(status) { where(status: status) }
  scope :filter_by_project_id, ->(project_id) { where(project_id: project_id) }
  scope :filter_by_booking_detail_id, ->(booking_detail_id) { where(booking_detail_id: booking_detail_id) }
  scope :filter_by_channel_partner_id, ->(channel_partner_id) { where(manager_id: channel_partner_id) }

  accepts_nested_attributes_for :incentive_deduction

  class << self
    def user_based_scope(user, params = {})
      custom_scope = {}
      if params[:booking_detail_id].blank? && !user.buyer?
        if user.role?('channel_partner')
          custom_scope = { booking_detail_id: { '$in': BookingDetail.in(lead_id: Lead.where(manager_id: user.id).distinct(:id)).distinct(:id) } }
        elsif user.role?('cp_admin')
          custom_scope = { booking_detail_id: { "$in": BookingDetail.in(lead_id: Lead.nin(manager_id: [nil, '']).distinct(:id)).distinct(:id) } }
        elsif user.role?('cp')
          channel_partner_ids = User.where(role: 'channel_partner').where(manager_id: user.id).distinct(:id)
          custom_scope = { booking_detail_id: { "$in": BookingDetail.in(lead_id: Lead.in(referenced_manager_ids: channel_partner_ids).distinct(:id)).distinct(:id) } }
        elsif user.role?('billing_team')
          custom_scope = { status: { '$ne': 'draft' } }
        end
      end
      if params[:booking_detail_id].present?
        custom_scope = { booking_detail_id: params[:booking_detail_id] }
        custom_scope[:status] = { '$ne': 'draft' } if user.role?('billing_team')
      end
      custom_scope = { booking_detail_id: { '$in': user.booking_details.distinct(:id) } } if user.buyer?
      custom_scope
    end
  end
end
