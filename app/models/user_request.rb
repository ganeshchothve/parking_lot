class UserRequest
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable
  include InsertionStringMethods

  field :comments, type: String
  field :status, type: String, default: 'pending'
  field :request_type, type: String, default: "cancellation"
  field :crm_comments, type: String # Comments from crm team
  field :reply_for_customer, type: String #reply from crm team to customer
  field :alternate_project_unit_id, type: BSON::ObjectId # in case of swap resolve

  enable_audit({
    associated_with: ["user"],
    indexed_fields: [:project_unit_id, :receipt_id],
    audit_fields: [:status, :request_type, :alternate_project_unit_id],
    reference_ids_without_associations: [
      {field: 'alternate_project_unit_id', klass: 'ProjectUnit'},
    ]
  })

  belongs_to :project_unit, optional: true
  belongs_to :receipt, optional: true
  belongs_to :user
  has_many :assets, as: :assetable

  validates :user_id, :project_unit_id, :comments, presence: true
  validates :status, inclusion: {in: Proc.new{ UserRequest.available_statuses.collect{|x| x[:id]} } }
  validates :project_unit_id, uniqueness: {scope: :user_id, message: 'already has a cancellation request.'}

  def self.available_statuses
    [
      {id: 'pending', text: 'Pending'},
      {id: 'resolved', text: 'Resolved'},
      {id: 'swapped', text: 'Swap resolved'}
    ]
  end

  # TODO: on create send email to CRM team

  def self.build_criteria params={}
    selector = {}
    if params[:fltrs].present?
      if params[:fltrs][:status].present?
        selector[:status] = params[:fltrs][:status]
      end
      if params[:fltrs][:user_id].present?
        selector[:user_id] = params[:fltrs][:user_id]
      end
    end
    self.where(selector)
  end

  def alternate_project_unit
    ProjectUnit.where(id: self.alternate_project_unit_id).first
  end
end
