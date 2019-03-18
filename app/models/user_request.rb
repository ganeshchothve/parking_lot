class UserRequest
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable
  include InsertionStringMethods
  include UserRequestStateMachine
  include FilterByCriteria

  STATUS = %w(pending processing resolved rejected failed)

  field :status, type: String # default: 'pending'
  field :resolved_at, type: DateTime
  field :reason_for_failure, type: String

  belongs_to :booking_detail
  belongs_to :project_unit, optional: true
  belongs_to :receipt, optional: true
  belongs_to :user
  belongs_to :resolved_by, class_name: "User", optional: true
  belongs_to :created_by, class_name: "User"
  has_many :assets, as: :assetable
  has_many :notes, as: :notable

  validates :user_id, :project_unit_id, presence: true
  #validates :resolved_by, presence: true, if: Proc.new{|user_request| user_request.status == 'resolved' }

  validates :status, inclusion: { in: STATUS }
  validates :project_unit_id, uniqueness: {scope: [:user_id, :status], message: 'already has a cancellation request.'}, if: Proc.new{|record| record.pending? }
  validates :reason_for_failure, presence: true, if: Proc.new{|record| record.rejected? }

  accepts_nested_attributes_for :notes

  default_scope -> {desc(:created_at)}


  # TODO: on create send email to CRM team

  class << self

    def user_based_scope(user, params={})
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
end
