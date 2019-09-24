class Checklist
  include Mongoid::Document

  TRACKED_BY = %w[manual system]

  field :name, type: String
  field :key, type: String
  field :description, type: String
  field :tracked_by, type: String, default: 'manual'

  embedded_in :client

  validates :name, :key, :tracked_by, presence: true
  validates :key, :name, uniqueness: true
  validates :tracked_by, inclusion: { in: proc { TRACKED_BY } }
  validates_format_of :key, :with => /\A[a-z0-9_]+\z/


end
