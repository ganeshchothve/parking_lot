class Template
  include Mongoid::Document
  include Mongoid::Timestamps
  extend FilterByCriteria
  include JSONStringParser

  field :content, type: String
  field :is_active, type: Boolean, default: false

  belongs_to :booking_portal_client, class_name: "Client"
  belongs_to :project, optional: true

  validates :content, presence: true

  scope :filter_by_project_id, ->(project_id) { where(project_id: project_id) }
  scope :filter_by__type, ->(type) { where(_type: type) }
  scope :filter_by_name, ->(name) { where(name: name) }
  scope :filter_by_subject_class, ->(subject_class) { where(subject_class: subject_class) }

  def parsed_content object
    begin
      return ERB.new(self.content).result( object.get_binding ).html_safe
    rescue Exception => e
      I18n.t("controller.templates.errors.contact_admin", name: self.class.name)
    end
  end

  def parsed_data record
    _request_erb = ERB.new(data.gsub("\n\s", '')) rescue ERB.new("Hash.new")
    _data = SafeParser.new(_request_erb.result(record.get_binding)).safe_load rescue {}
    recursive_json_string_parser(_data)
  end

  def self.user_based_scope(user, params = {})
    custom_scope = {}
    if user.role.in?(%w(superadmin))
      custom_scope = {  }
    end
    custom_scope.merge!({booking_portal_client_id: user.booking_portal_client.id})
    custom_scope
  end

end
