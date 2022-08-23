class PaymentAdjustment
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :field, type: String
  field :formula, type: String
  field :absolute_value, type: Float
  field :editable, type: Boolean

  belongs_to :booking_portal_client, class_name: 'Client'
  embedded_in :payable, polymorphic: true

  validates :name, :field, presence: true, unless: -> { payable.class.to_s.in?(%w(Ladder Invoice::Manual Invoice::Calculated)) }
  validate :formula_or_absolute_value

  def value object
    (absolute_value.present? ? absolute_value : calculate(object)) rescue 0
  end


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

  private
  
  def formula_or_absolute_value
    if self.formula.blank? && self.absolute_value.blank?
      if self.payable.is_a? Ladder
        self.errors.add(:base, 'Formula or value is required for Incentive calculation')
      else
        self.errors.add(:base, "Formula or value is required on payment adjustment")
      end
    end
  end
end
