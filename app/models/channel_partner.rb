class ChannelPartner
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable

  field :name, type: String
  field :email, type: String
  field :phone, type: String
  field :rera_id, type: String
  field :location, type: String
  field :associated_user_id, type: BSON::ObjectId
  field :status, type: String, default: 'inactive'

  validates :name, :email, :phone, :rera_id, :location, :status, presence: true
  validates :phone, uniqueness: true, phone: true # TODO: we can remove phone validation, as the validation happens in sell.do
  validates :email, :rera_id, uniqueness: true, allow_blank: true
  validates :status, inclusion: {in: Proc.new{ ChannelPartner.available_statuses.collect{|x| x[:id]} } }
  validate :user_level_uniqueness
  validate :cannot_make_inactive

  def self.available_statuses
    [
      {id: 'active', text: 'Active'},
      {id: 'inactive', text: 'Inactive'}
    ]
  end

  def associated_user
    if self.associated_user_id.present?
      return User.find(self.associated_user_id)
    else
      return nil
    end
  end

  private
  def user_level_uniqueness
    if self.new_record? || (self.status_changed? && self.status == 'active')
      user = User.or([{email: self.email}, {phone: self.phone}]).first
      if user.present? && user.id != self.associated_user_id
        self.errors.add :base, "Email or Phone has already been taken"
      end
    end
  end

  def cannot_make_inactive
    if self.status_changed? && self.status == 'inactive'
      self.errors.add :status, ' cannot be reverted to "inactive" once activated'
    end
  end
end
