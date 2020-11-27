class Invoice
  include Mongoid::Document
  include Mongoid::Timestamps
  include InsertionStringMethods
  extend FilterByCriteria

  field :amount, type: Float, default: 0.0
  field :status, type: String, default: 'pending'
  field :registration_status, type: String
  field :raised_date, type: Date
  field :processing_date, type: Date
  field :approved_date, type: Date
  field :cheque_handover_date, type: Date
  field :comments, type: String
  field :ladder_id, type: BSON::ObjectId
  field :ladder_stage, type: Integer

  belongs_to :project
  belongs_to :booking_detail
  belongs_to :incentive_scheme
  has_one :cheque, class_name: 'Receipt'

  validates :ladder_id, :ladder_stage, presence: true
  validates :booking_detail_id, uniqueness: { scope: [:incentive_scheme_id, :ladder_id] }
  validates :amount, numericality: { greater_than: 0 }


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
        end
      end

      custom_scope = { booking_detail_id: params[:booking_detail_id] } if params[:booking_detail_id].present?
      custom_scope = { booking_detail_id: { '$in': user.booking_details.distinct(:id) } } if user.buyer?
      custom_scope
    end
  end
end
