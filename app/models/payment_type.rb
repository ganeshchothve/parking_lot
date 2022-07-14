class PaymentType
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :formula, type: String
  field :absolute_value, type: Float

  belongs_to :booking_portal_client, class_name: 'Client', optional: true

  validates :name, presence: true
  validate :formula_or_absolute_value

  def value object
    (absolute_value.present? ? absolute_value : calculate(object)) rescue 0
  end

  private

  def calculate object
    if object.present?
      begin
        return ERB.new("<%= #{self.formula} %>").result( object.get_binding ).to_f
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
