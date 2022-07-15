class ThirdPartyReference
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic

  field :reference_id, type: String

  embedded_in :reference_model, polymorphic: true
  belongs_to :booking_portal_client, class_name: 'Client'
  belongs_to :crm, class_name: 'Crm::Base'
  validates_uniqueness_of :crm_id, scope: :reference_model

  after_save :update_references

  def update_references
    case self._parent.class.name
    when 'ChannelPartner'
      #if cp_user = self._parent.associated_user.presence
      #  cp_user.update_external_ids({reference_id: self.reference_id}, self.crm_id.to_s)
      #end
    when 'Lead', 'User'
      if self.crm.try(:domain) == ENV_CONFIG.dig(:selldo, :base_url) && self._parent.lead_id.blank?
        self._parent.set(lead_id: self.reference_id)
      end
    when 'SiteVisit'
      if self.crm.try(:domain) == ENV_CONFIG.dig(:selldo, :base_url) && self._parent.selldo_id.blank?
        self._parent.set(selldo_id: self.reference_id)
      end
    when /Invoice/
      if self.crm.try(:domain) == ENV_CONFIG.dig(:razorpay, :base_url) && self._parent.may_paid?
        self._parent.paid!
      end
    end
  end
end
