class ThirdPartyReference
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic

  field :reference_id, type: String

  embedded_in :reference_model, polymorphic: true
  belongs_to :crm, class_name: 'Crm::Base'
  validates_uniqueness_of :crm_id, scope: :reference_model

  after_save :update_references

  def update_references
    if self._parent.class == ChannelPartner
      if cp_user = self._parent.associated_user.presence
        cp_user.update_external_ids({reference_id: self.reference_id}, self.crm_id.to_s)
      end
    end
  end
end
