class Template
  include Mongoid::Document
  include Mongoid::Timestamps
  extend FilterByCriteria

  field :content, type: String
  field :is_active, type: Boolean, default: false

  belongs_to :booking_portal_client, class_name: "Client"
  belongs_to :project, optional: true

  validates :content, presence: true

  scope :filter_by_project_id, ->(project_id) { where(project_id: project_id) }
  scope :filter_by__type, ->(type) { where(_type: type) }

  def parsed_content object
    begin
      return ERB.new(self.content).result( object.get_binding ).html_safe
    rescue Exception => e
      "We are sorry! #{self.class.name} has some issue. Please Contact to Administrator."
    end
  end
end
