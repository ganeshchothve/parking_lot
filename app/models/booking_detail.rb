class BookingDetail
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable

  field :primary_user_kyc_id, type: BSON::ObjectId
  field :status, type: String
  field :channel_partner_id, type: BSON::ObjectId
  mount_uploader :tds_doc, DocUploader

  belongs_to :project_unit
  belongs_to :user
  has_many :receipts
  has_and_belongs_to_many :user_kycs
  embeds_many :booking_detail_status_changes

  validates :status, :primary_user_kyc_id, presence: true

  def self.run_sync project_unit_id, changes={}
    project_unit = ProjectUnit.find(project_unit_id)
    changes = changes.with_indifferent_access
    booking_detail = project_unit.booking_detail

    if booking_detail.blank?
      if ["blocked", "booked_tentative", "booked_confirmed"].include?(project_unit.status)
        BookingDetail.create(project_unit_id: project_unit.id, user_id: project_unit.user_id, receipt_ids: project_unit.receipt_ids, user_kyc_ids: project_unit.user_kyc_ids, primary_user_kyc_id: project_unit.primary_user_kyc_id, status: project_unit.status, channel_partner_id: project_unit.user.channel_partner_id)
      end
    elsif booking_detail.status != "cancelled"
      if changes["status"].present? && ["blocked", "booked_tentative", "booked_confirmed", "error"].include?(changes["status"][0]) && ["blocked", "booked_tentative", "booked_confirmed", "error"].include?(project_unit.status)
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
    message = "#{self.primary_user_kyc.first_name} from #{self.primary_user_kyc.address.city rescue "-"} just booked #{self.project_unit.name}"
    Gamification::PushNotification.new.push(message)
  end
end
