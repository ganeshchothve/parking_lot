class Parameter
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable
  include ApplicationHelper
  include InsertionStringMethods

  field :name, type: String
  field :key, type: String
  field :value, type: String

  belongs_to :booking_portal_client, class_name: 'Client', optional: true
  embedded_in :parameterizable, polymorphic: true

  validates :name, :key, :value, presence: true
  validates :key, uniqueness: {scope: :parameterizable_id}, format: {with: /\A[a-z_]+\z/, message: "Only small letters & underscore allowed"}
end
