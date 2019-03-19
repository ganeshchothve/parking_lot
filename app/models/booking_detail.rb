class BookingDetail
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable
  include InsertionStringMethods
  include SyncDetails
  include BookingDetailStateMachine


  field :primary_user_kyc_id, type: BSON::ObjectId
  field :status, type: String
  field :erp_id, type: String, default: ''
  mount_uploader :tds_doc, DocUploader

  enable_audit(
    indexed_fields: %i[manager_id project_unit_id],
    audit_fields: %i[manager_id status manager_id project_unit_id user_id user_kyc_ids],
    reference_ids_without_associations: [
      { field: 'manager_id', klass: 'ChannelPartner' },
      { field: 'primary_user_kyc_id', klass: 'UserKyc' }
    ]
  )

  belongs_to :project_unit
  belongs_to :user
  belongs_to :manager, class_name: 'User', optional: true
  belongs_to :search, optional: true
  has_many :receipts
  has_and_belongs_to_many :user_kycs
  has_many :smses, as: :triggered_by, class_name: 'Sms'
  has_many :booking_detail_schemes, class_name: 'BookingDetailScheme', inverse_of: :booking_detail,:dependent => :destroy
  has_many :sync_logs, as: :resource

  validates :status, :primary_user_kyc_id, presence: true
  validates :erp_id, uniqueness: true, allow_blank: true

  default_scope -> { desc(:created_at) }

  def self.run_sync(project_unit_id, changes = {})
    project_unit = ProjectUnit.find(project_unit_id)
    changes = changes.with_indifferent_access
    booking_detail = project_unit.booking_detail

    if booking_detail.present? && booking_detail.status != 'cancelled'
      if changes['status'].present? && %w[blocked booked_tentative booked_confirmed error].include?(changes['status'][0]) && %w[blocked booked_tentative booked_confirmed error].include?(project_unit.status)
        booking_detail.status = project_unit.status
      end

      if changes['status'].present? && changes['status'][0] == 'under_negotiation' && project_unit.status == 'negotiation_failed'
        booking_detail.status = project_unit.status
      end

      if changes['status'].present? && %w[blocked booked_tentative booked_confirmed error].include?(changes['status'][0]) && ProjectUnit.user_based_available_statuses(booking_detail.user).include?(project_unit.status)
        booking_detail.status = 'cancelled'
      end
      if changes['user_kyc_ids'].present?
        booking_detail.user_kyc_ids = project_unit.user_kyc_ids
      end
      if changes['receipt_ids'].present?
        booking_detail.receipt_ids = project_unit.receipt_ids
      end
      booking_detail.save!
    end
  end

  def primary_user_kyc
    UserKyc.find(primary_user_kyc_id) if primary_user_kyc_id.present?
  end
  
  def self.available_statuses
    [
      { id: 'available', text: 'Available' },
      { id: 'under_negotiation', text: 'Under negotiation' },
      { id: 'scheme_rejected', text: 'Scheme Rejected' },
      { id: 'scheme_approved', text: 'Scheme Approved' },
      { id: 'hold', text: 'Hold' },
      { id: 'blocked', text: 'Blocked' },
      { id: 'booked_tentative', text: 'Tentative Booked' },
      { id: 'booked_confirmed', text: 'Confirmed Booked' },
      { id: 'swap_requested', text: 'Swap Requested' },
      { id: 'swapping', text: 'Swapping' },
      { id: 'swapped', text: 'Swapped' },
      { id: 'swap_rejected', text: 'Swap Rejected' },
      { id: 'cancellation_requested', text: 'Cancellation Requested' },
      { id: 'cancelling', text: 'Cancelling' },
      { id: 'cancelled', text: 'Cancelled' },
      { id: 'cancellation_rejected', text: 'Cancellation Rejected' }
    ]
  end

  def send_notification!
    message = "#{primary_user_kyc.name} just booked apartment #{project_unit.name} in #{project_unit.project_tower_name}"
    Gamification::PushNotification.new.push(message) if Rails.env.staging? || Rails.env.production?
  end

  def booking_detail_scheme
    booking_detail_schemes.where(status: 'approved').first
  end


  def sync(erp_model, sync_log)
    Api::BookingDetailsSync.new(erp_model, self, sync_log).execute
  end

end
