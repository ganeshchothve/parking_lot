class Offer
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable
  include InsertionStringMethods
  include ApplicationHelper
  extend ApplicationHelper

  CATEGORIES = %w( rate white_goods direct tax )
  PROVIDED_BY = %w( launchpad developer )

  field :category, type: String
  field :short_description, type: String
  field :description, type: String
  field :provided_by, type: String, default: 'developer'
  
  belongs_to :project

  validates :category, :description, :short_description, :provided_by, presence: true
  validates :category, inclusion: { in: ::Offer::CATEGORIES }, allow_blank: true
  validates :provided_by, inclusion: { in: ::Offer::PROVIDED_BY }, allow_blank: true
end