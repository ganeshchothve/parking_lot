class PortalStagePriority
	include Mongoid::Document
	include Mongoid::Timestamps

	field :stage, type: String
	field :priority, type: Integer

	validates :stage, :priority, presence: true

end
