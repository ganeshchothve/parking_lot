class EmailTemplate
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name,type: String
  field :subject_class, type: String
  field :description,type: String
  field :subject,type: String
  field :body,type: String
  field :text_only_body,type: String
  field :attachment_ids, type: Array, default: []

  validates :name, :subject, :subject_class, presence: true
  validate :body_or_text_only_body_present?

  belongs_to :booking_portal_client, class_name: 'Client', inverse_of: :email_templates

  def attachments
    self.agency.docs.in(id: self.attachment_ids)
  end

  private
  # for email template we require body or text. Otherwisse we won't have any content to send to the sender / reciever
  # throws error if the both are blank
  #
  def body_or_text_only_body_present?
    if self.body.blank? && self.text_only_body.blank?
      self.errors.add(:base,"Either html-body or text only content is required.")
    end
  end

end
