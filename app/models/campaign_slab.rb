class CampaignSlab
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable
  include InsertionStringMethods
  include ApplicationHelper
  extend ApplicationHelper

  field :name, type: String
  field :minimum_investment_amount, type: Integer
  field :recommended, type: Boolean, default: false
  
  embedded_in :campaign

  validates :name, :minimum_investment_amount, presence: true
  validates :minimum_investment_amount, numericality: { greater_than: 0 }
end
