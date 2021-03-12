class IncentiveDeduction
  include Mongoid::Document
  include Mongoid::Timestamps
  include NumberIncrementor
  include InsertionStringMethods
  include IncentiveDeductionStateMachine

  DOCUMENT_TYPES = []

  field :amount, type: Float, default: 0.0
  field :status, type: String, default: 'draft'
  field :comments, type: String

  validates :amount, :comments, presence: true
  validates :amount, numericality: { less_than_or_equal_to: proc { |deduction| deduction.invoice.amount }, greater_than: 0 }
  validates :assets, presence: true, if: :pending_approval?

  belongs_to :invoice
  belongs_to :creator, class_name: 'User'
  has_many :assets, as: :assetable

  accepts_nested_attributes_for :assets, reject_if: proc { |attrs| attrs['file'].blank? }

  def get_status
    case status
    when "draft"
      "Draft"
    when "pending_approval"
      "Pending Approval"
    when "approved"
      "Approved"
    when "rejected"
      "Rejected"
    else
      status
    end
  end

  class << self
    def user_based_scope(user, params = {})
      custom_scope = {}
      if params[:invoice_id].present?
        custom_scope = { invoice_id: params[:invoice_id] }
        custom_scope[:status] = { '$ne': 'draft' } if user.role?('billing_team')
      end
      custom_scope
    end
  end
end
