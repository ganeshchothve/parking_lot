class Cost
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable
  include ApplicationHelper
  include InsertionStringMethods

  field :name, type: String
  field :key, type: String
  field :formula, type: String
  field :new_formula, type: String
  field :absolute_value, type: Float
  field :new_absolute_value, type: Float
  field :category, type: String
  field :order, type: Integer

  embedded_in :costable, polymorphic: true

  validates :name, :key, :category, presence: true
  validates :key, uniqueness: {scope: :costable_id}, format: {with: /\A[a-z_]+\z/, message: "Only small letters & underscore allowed"}
  validates :formula, presence: true, if: Proc.new{|cost| cost.absolute_value.blank? }
  validates :absolute_value, presence: true, if: Proc.new{|cost| cost.formula.blank? }
  validates :category, inclusion: {in: I18n.t("mongoid.attributes.cost/available_categories").keys.map(&:to_s) }

  default_scope -> {asc(:order)}

  def value
    out = (absolute_value.present? ? absolute_value : calculate) rescue 0
    if costable.is_a?(ProjectUnit)
      out += costable.scheme.payment_adjustments.where(field: self.key).collect{ |adj| adj.value(self.costable)}.sum
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
