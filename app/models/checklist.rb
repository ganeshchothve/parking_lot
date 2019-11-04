class Checklist
  include Mongoid::Document

  TRACKED_BY = %w[manual system]

  field :name, type: String
  field :key, type: String
  field :description, type: String
  field :tracked_by, type: String, default: 'manual'
  field :order, type: Integer

  embedded_in :client

  validates :name, :key, :tracked_by, :order, presence: true
  validates :key, :name, :order, uniqueness: true
  validates :tracked_by, inclusion: { in: proc { TRACKED_BY } }
  validates :key, format: {with: /\A[a-z0-9_]+\z/, message: "can take small letters, numbers & underscores only"}


end
