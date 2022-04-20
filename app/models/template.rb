class Template
  include Mongoid::Document
  include Mongoid::Timestamps
  extend FilterByCriteria

  field :content, type: String
  field :is_active, type: Boolean, default: false
  field :data, type: String

  belongs_to :booking_portal_client, class_name: "Client"
  belongs_to :project, optional: true

  validates :content, presence: true

  scope :filter_by_project_id, ->(project_id) { where(project_id: project_id) }
  scope :filter_by__type, ->(type) { where(_type: type) }
  scope :filter_by_name, ->(name) { where(name: name) }

  def parsed_content object
    begin
      return ERB.new(self.content).result( object.get_binding ).html_safe
    rescue Exception => e
      "We are sorry! #{self.class.name} has some issue. Please Contact to Administrator."
    end
  end

  def set_request_payload record
    _request_erb = ERB.new(data.gsub("\n\s", '')) rescue ERB.new("Hash.new")
    _data = SafeParser.new(_request_erb.result(record.get_binding)).safe_load rescue {}
    safe_parse(_data)
  end

  def safe_parse(data)
    res = data
    case (res ||= data)
    when Hash
      res.each do |key, value|
        _value = (SafeParser.new(value).safe_load rescue nil) || value
        res[key] = ((_value.is_a?(Hash) || _value.is_a?(Array)) ? safe_parse(_value) : value)
      end
      res
    when Array
      res.map! do |value|
        _value = (SafeParser.new(value).safe_load rescue nil) || value
        (_value.is_a?(Hash) || _value.is_a?(Array)) ? safe_parse(_value) : value
      end
      Array.new.push(*res)
    else
      res
    end
  end

end
