class PaymentAdjustment
  include Mongoid::Document
  include Mongoid::Timestamps

  field :field, type: String
  field :formula, type: String
  field :absolute_value, type: Float

  embedded_in :scheme

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
end
