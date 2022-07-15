class Campaign
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable
  include InsertionStringMethods
  include CrmIntegration
  include CampaignStateMachine
  include ApplicationHelper
  extend ApplicationHelper
  extend FilterByCriteria

  field :name, type: String
  field :description, type: String
  field :focus, type: String
  field :about_campaign_manager, type: String
  field :terms_and_conditions, type: String
  field :campaign_slab_offer_text, type: String
  field :campaign_slab_offer_percentage, type: String
  field :campaign_slab_offer_amount, type: String
  field :campaign_id, type: String
  field :total_budget, type: Integer
  field :total_invested_amount, type: Integer, default: 0
  field :start_date, type: Date
  field :end_date, type: Date
  field :campaign_type, type: String, default: 'pool_funded'
  field :status, type: String, default: 'draft'
  field :estimated_cost_per_lead, type: Integer
  field :sources, type: Array
  field :target_areas, type: Array
  
  belongs_to :booking_portal_client, class_name: 'Client'
  belongs_to :creator, class_name: 'User'
  belongs_to :campaign_manager, class_name: 'User'
  has_and_belongs_to_many :projects

  embeds_many :campaign_budgets
  embeds_many :campaign_slabs

  has_many :interested_campaigns, dependent: :destroy
  has_many :assets, as: :assetable, dependent: :destroy
  has_many :meetings
  has_many :faqs, as: :questionable, dependent: :destroy

  validates :name, :about_campaign_manager, :terms_and_conditions, :total_budget, :total_invested_amount, :start_date, :end_date, :campaign_type, :focus, :status, :estimated_cost_per_lead, :sources, :creator_id, :campaign_manager_id, presence: true
  validates :sources, array: { inclusion: {allow_blank: false, in: proc { |campaign| Campaign.sources.collect{|x| x[:id] } } } }
  validates :status, inclusion: { in: proc { |campaign| Campaign.statuses.collect{|x| x[:id] } } }, allow_blank: true
  validates :focus, inclusion: { in: proc { |campaign| Campaign.focuses.collect{|x| x[:id] } } }, allow_blank: true
  validates :campaign_type, inclusion: { in: proc { |campaign| Campaign.campaign_types.collect{|x| x[:id] } } }, allow_blank: true
  validates :total_budget, :estimated_cost_per_lead, numericality: { greater_than: 0, only_integer: true }, allow_blank: true
  validates :total_invested_amount, numericality: { greater_than_or_equal_to: 0, only_integer: true }, allow_blank: true
  validates :campaign_slabs, :campaign_budgets, length: { minimum: 1 }
  validate :validate_start_and_end_date

  accepts_nested_attributes_for :campaign_budgets, :campaign_slabs, :interested_campaigns, :assets, :faqs

  def self.statuses
    [
      { id: 'draft', text: 'Draft' },
      { id: 'funding', text: 'Funding' },
      { id: 'funded', text: 'Funded' },
      { id: 'live', text: 'Live' },
      { id: 'paused', text: 'Paused' },
      { id: 'cancelled', text: 'Cancelled' },
      { id: 'completed', text: 'Completed' }
    ]
  end

  def self.focuses
    [
      { id: 'project_based', text: 'Project based' },
      { id: 'area_based', text: 'Area based' }
    ]
  end

  def self.campaign_types
    [
      { id: 'pool_funded', text: 'Pool Funded' }
    ]
  end

  def self.sources
    [
      { id: 'google', text: 'Google' },
      { id: 'fb', text: 'Facebook' }
    ]
  end

  def self.user_based_scope(user, params = {})
    custom_scope = {}
    custom_scope
  end

  private
  def validate_start_and_end_date
    self.errors.add :start_date, ' cannot be in the past' if new_record? &&  start_date.present? && start_date < Date.today
    self.errors.add :end_date, ' cannot be in the past' if new_record? && end_date.present? && end_date < Date.today
    self.errors.add :end_date, ' cannot be less or equal to the start date' if start_date.present? && end_date.present? && start_date >= end_date
  end
end
