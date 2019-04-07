class BookingDetail
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable
  include InsertionStringMethods
  include BookingDetailStateMachine
  include SyncDetails

  BOOKING_STAGES = %w[blocked booked_tentative booked_confirmed]

  field :status, type: String
  field :erp_id, type: String, default: ''
  field :name, type: String
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
  # When a new booking detail object is created from another object, this field will be set. This happens when the user creates a swap request.
  belongs_to :parent_booking_detail, class_name: 'BookingDetail', optional: true
  belongs_to :primary_user_kyc, class_name: 'UserKyc'
  has_many :receipts, dependent: :nullify
  has_many :smses, as: :triggered_by, class_name: 'Sms'
  has_many :booking_detail_schemes, dependent: :destroy
  has_many :sync_logs, as: :resource
  has_many :notes, as: :notable
  has_many :user_requests
  has_and_belongs_to_many :user_kycs

  # TODO: uncomment
  # validates :name, presence: true
  validates :status, :primary_user_kyc_id, presence: true
  validates :erp_id, uniqueness: true, allow_blank: true
  delegate :name, to: :project_unit, prefix: true, allow_nil: true

  accepts_nested_attributes_for :notes

  default_scope -> { desc(:created_at) }

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

  class << self
    def run_sync(project_unit_id, changes = {})
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
  end
end
