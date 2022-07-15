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

  belongs_to :booking_portal_client, class_name: 'Client'
  
  validates :name, :minimum_investment_amount, presence: true
  validates :minimum_investment_amount, numericality: { greater_than: 0 }
end
