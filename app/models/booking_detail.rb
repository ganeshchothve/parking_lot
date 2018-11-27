class BookingDetail
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable
  include InsertionStringMethods

  field :primary_user_kyc_id, type: BSON::ObjectId
  field :status, type: String
  field :manager_id, type: BSON::ObjectId
  mount_uploader :tds_doc, DocUploader

  enable_audit({
    indexed_fields: [:manager_id, :project_unit_id],
    audit_fields: [:manager_id, :status, :manager_id, :project_unit_id, :user_id, :user_kyc_ids],
    reference_ids_without_associations: [
      {field: 'manager_id', klass: 'ChannelPartner'},
      {field: 'primary_user_kyc_id', klass: 'UserKyc'}
    ]
  })

  belongs_to :project_unit
  belongs_to :user
  has_many :receipts
  has_and_belongs_to_many :user_kycs
  has_many :smses, as: :triggered_by, class_name: "Sms"
  has_many :booking_detail_schemes, class_name: 'BookingDetailScheme', inverse_of: :booking_detail

  validates :status, :primary_user_kyc_id, presence: true

  default_scope -> {desc(:created_at)}

  def self.run_sync project_unit_id, changes={}
    project_unit = ProjectUnit.find(project_unit_id)
    changes = changes.with_indifferent_access
    booking_detail = project_unit.booking_detail

    if booking_detail.present? && booking_detail.status != "cancelled"
      if changes["status"].present? && ["blocked", "booked_tentative", "booked_confirmed", "error"].include?(changes["status"][0]) && ["blocked", "booked_tentative", "booked_confirmed", "error"].include?(project_unit.status)
        booking_detail.status = project_unit.status
      end

      if changes["status"].present? && changes["status"][0] == "under_negotiation" && project_unit.status == "negotiation_failed"
        booking_detail.status = project_unit.status
      end

      if changes["status"].present? && ["blocked", "booked_tentative", "booked_confirmed", "error"].include?(changes["status"][0]) && ProjectUnit.user_based_available_statuses(booking_detail.user).include?(project_unit.status)
        booking_detail.status = "cancelled"
      end
      if changes["user_kyc_ids"].present?
        booking_detail.user_kyc_ids = project_unit.user_kyc_ids
      end
      if changes["receipt_ids"].present?
        booking_detail.receipt_ids = project_unit.receipt_ids
      end
      booking_detail.save!
    end
  end

  def primary_user_kyc
    if primary_user_kyc_id.present?
      UserKyc.find(primary_user_kyc_id)
    else
      nil
    end
  end

  def send_notification!
    message = "#{self.primary_user_kyc.name} just booked apartment #{self.project_unit.name} in #{self.project_unit.project_tower_name}"
    Gamification::PushNotification.new.push(message) if Rails.env.staging? || Rails.env.production?
  end

  def booking_detail_scheme
    self.booking_detail_schemes.where(status: "approved").first
  end

end
