class ProjectUnitStateChange
  include Mongoid::Document

  field :status, type: String
  field :status_was, type: String
  field :changed_on, type: DateTime

  embedded_in :project_unit
end
