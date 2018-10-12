class PaymentAdjustment
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :field, type: String
  field :formula, type: String
  field :absolute_value, type: Float

  embedded_in :payable, polymorphic: true

  validates :name, :field, presence: true
  validate :formula_or_absolute_value

  def value
    (absolute_value.present? ? absolute_value : calculate) rescue 0
  end

  private

  def calculate
    project_unit = self.scheme.project_unit
    if project_unit.present?
      begin
        return ERB.new("<%= #{self.formula} %>").result( project_unit.get_binding ).to_f
      rescue
        return 0
      end
    else
      0
    end
  end

  def formula_or_absolute_value
    if self.formula.blank? && self.absolute_value.blank?
      self.errors.add(:base, "Formula or value is required on payment adjustment")
    end
  end
end
