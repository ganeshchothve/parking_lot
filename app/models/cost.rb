class Cost
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable
  include ApplicationHelper
  include InsertionStringMethods

  field :name, type: String
  field :formula, type: String
  field :absolute_value, type: Float
  field :category, type: String
  field :order, type: Integer

  embedded_in :costable, polymorphic: true

  validates :name, :category, presence: true
  validates :formula, presence: true, if: Proc.new{|cost| cost.absolute_value.blank? }
  validates :absolute_value, presence: true, numericality: { greater_than: 0 }, if: Proc.new{|cost| cost.formula.blank? }
  validates :category, inclusion: {in: Proc.new{ Cost.available_categories.collect{|x| x[:id]} } }

  default_scope -> {asc(:order)}

  def self.available_categories
    [
      {id: 'agreement', text: 'Part of Agreement Value'},
      {id: 'outside_agreement', text: 'In addition to Agreement Value'},
      {id: 'tax', text: 'Government Tax'}
    ]
  end

  def value
    absolute_value.present? && absolute_value > 0 ? absolute_value : calculate
  end

  private
  def calculate
    begin
      f = TemplateParser.parse(self.formula, self)
      eval(f).to_f
    rescue

    end
  end
end
