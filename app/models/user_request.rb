class UserRequest
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable
  include InsertionStringMethods

  field :status, type: String, default: 'pending'
  field :resolved_at, type: DateTime

  belongs_to :project_unit, optional: true
  belongs_to :receipt, optional: true
  belongs_to :user
  belongs_to :resolved_by, class_name: "User", optional: true
  belongs_to :created_by, class_name: "User"
  has_many :assets, as: :assetable
  has_many :notes, as: :notable

  validates :user_id, :project_unit_id, presence: true
  validates :resolved_by, presence: true, if: Proc.new{|user_request| user_request.status == 'resolved' }
  validates :status, inclusion: {in: Proc.new{ |record| record.class.available_statuses.collect{|x| x[:id]} } }
  # validates :project_unit_id, uniqueness: {scope: :user_id, message: 'already has a cancellation request.'}

  accepts_nested_attributes_for :notes

  default_scope -> {desc(:created_at)}

  def self.available_statuses
    [
      {id: 'pending', text: 'Pending'},
      {id: 'resolved', text: 'Resolved'},
      {id: 'rejected', text: 'Rejected'}
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


  def self.user_based_scope(user, params={})
    custom_scope = {}
    if params[:user_id].blank? && !user.buyer?
      if user.role?('channel_partner')
        custom_scope = {user_id: {"$in": User.where(referenced_manager_ids: user.id).distinct(:id)}}
      elsif user.role?('cp_admin')
        custom_scope = {user_id: {"$in": User.where(role: "user").nin(manager_id: [nil, ""]).distinct(:id)}}
      elsif user.role?('cp')
        channel_partner_ids = User.where(role: "channel_partner").where(manager_id: user.id).distinct(:id)
        custom_scope = {user_id: {"$in": User.in(referenced_manager_ids: channel_partner_ids).distinct(:id)}}
      end
    end

    custom_scope = {user_id: params[:user_id]} if params[:user_id].present?
    custom_scope = {user_id: user.id} if user.buyer?

    custom_scope[:project_unit_id] = params[:project_unit_id] if params[:project_unit_id].present?
    custom_scope
  end
end
