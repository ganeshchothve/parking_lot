class Template
  include Mongoid::Document
  include Mongoid::Timestamps

  field :content, type: String
  field :is_active, type: Boolean, default: false

  belongs_to :booking_portal_client, class_name: "Client"
  belongs_to :project, optional: true

  validates :content, presence: true

  def parsed_content object
    begin
      return ERB.new(self.content).result( object.get_binding ).html_safe
    rescue Exception => e
      "We are sorry! #{self.class.name} has some issue. Please Contact to Administrator."
    end

  end

  def self.build_criteria params={}
    selector = {}
    if params[:fltrs].present?
      if params[:fltrs][:_type].present?
        selector[:_type] = params[:fltrs][:_type]
      end
    end
    self.where(selector)
  end
end
