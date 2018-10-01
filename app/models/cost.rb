class Cost
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable
  include ApplicationHelper
  include InsertionStringMethods

  field :name, type: String
  field :key, type: String
  field :formula, type: String
  field :absolute_value, type: Float
  field :category, type: String
  field :order, type: Integer

  embedded_in :costable, polymorphic: true

  validates :name, :key, :category, presence: true
  validates :key, uniqueness: {scope: :costable_id}, format: {with: /\A[a-z_]+\z/, message: "Only small letters & underscore allowed"}
  validates :formula, presence: true, if: Proc.new{|cost| cost.absolute_value.blank? }
  validates :absolute_value, presence: true, if: Proc.new{|cost| cost.formula.blank? }
  validates :category, inclusion: {in: Proc.new{ Cost.available_categories.collect{|x| x[:id]} } }

  default_scope -> {asc(:order)}

  def self.available_categories
    [
      {id: 'agreement', text: 'Part of Agreement Value'},
      {id: 'outside_agreement', text: 'In addition to Agreement Value'} #,
      # {id: 'tax', text: 'Government Tax'}
    ]
  end

  def value
    out = (absolute_value.present? ? absolute_value : calculate) rescue 0
    if costable.is_a?(ProjectUnit)
      out += costable.scheme.payment_adjustments.where(field: self.key).collect{ |adj| adj.value}.sum
    end
    out
  end

  private
  def calculate
    begin
      return ERB.new("<%= #{self.formula} %>").result( costable.get_binding ).to_f
    rescue
      return 0
    end
  end
end
