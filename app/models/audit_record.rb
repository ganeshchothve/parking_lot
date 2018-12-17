class AuditRecord
  include Mongoid::Document
  extend FilterByCriteria
  store_in collection: 'audits'

  field :subject_class, type: String, default: ''
  field :modified_at, type: String
  field :user_name, type: String, default: ''
  field :change_type, type: String, default: ''

  has_many :audit_entries

  scope :filter_by_change_type, ->(_change_type) { where(change_type: _change_type) }
  scope :filter_by_subject_class, ->(_subject_class) { where(subject_class: _subject_class) }
  scope :filter_by_user_name, ->(_user_name) { where(user_name: _user_name) }
  scope :filter_by_modified_at, ->(_modified_at) { where(modified_at: _modified_at) }

end
