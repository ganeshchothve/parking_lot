class Datum
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable
  include ApplicationHelper
  include InsertionStringMethods

  field :name, type: String
  field :key, type: String
  field :formula, type: String
  field :absolute_value, type: Float
  field :order, type: Integer

  embedded_in :data_attributable, polymorphic: true

  validates :name, :key, presence: true
  validates :key, uniqueness: {scope: :data_attributable_id}, format: {with: /\A[a-z_]+\z/, message: "Only small letters & underscore allowed"}
  validates :formula, presence: true, if: Proc.new{|data_attribute| data_attribute.absolute_value.blank? }
  validates :absolute_value, presence: true, numericality: { greater_than: 0 }, if: Proc.new{|data_attribute| data_attribute.formula.blank? }

  default_scope -> {asc(:order)}

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
