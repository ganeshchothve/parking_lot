class CampaignBudget
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable
  include InsertionStringMethods
  include ApplicationHelper
  extend ApplicationHelper

  field :source, type: String
  field :total_budget, type: Integer
  field :total_spent, type: Integer, default: 0

  validates :source, :total_budget, :total_spent, presence: true
  validates :total_budget, numericality: { greater_than: 0 }
end
