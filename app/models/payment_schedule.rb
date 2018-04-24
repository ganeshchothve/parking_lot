class PaymentSchedule
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :display_order, type: Integer
  field :status, type: String, default: 'Pending'
  field :due_date, type: DateTime
  field :land_cost, type: Float
  field :construction_cost, type: Float
  field :installment_percent, type: Integer
  field :basic_installment_amount, type: Float
  field :tds_percent, type: Integer
  field :tds_amount, type: Float
  field :amount_received, type: Float
  field :infrastructure_charges, type: Float
  field :maintenance_deposit, type: Float
  field :power_supply, type: Float
  field :club_charges, type: Float
  field :corpus_fund_charges, type: Float
  field :payment_schedule_type, type: String

  # Associations
  # belongs_to :project_unit

  # Validations
  validates :name, :display_order, :due_date, :land_cost, :construction_cost, :installment_percent, :basic_installment_amount, :tds_percent, :tds_amount, :amount_received, :infrastructure_charges, :maintenance_deposit, :power_supply, :club_charges, :corpus_fund_charges, :payment_schedule_type, presence: true


  # Data to be sent to SFDC
  def self.api_json(project_unit)
    data = []
    PaymentSchedule.each do |ps|
      user = project_unit.user
      opp_id = user.lead_id + project_unit.sfdc_id
      hash = {
        opp_id: opp_id,
        selldo_lead_id: user.lead_id,
        unit_sfdc_id: project_unit.sfdc_id,
        payment_schedule_id: ps.id.to_s,
        name: ps.name,
        display_order: ps.display_order,
        status: "Pending",
        due_date: project_unit.blocking_payment.created_at.strftime("%Y-%m-%d"),
        land_cost: project_unit.land_rate.round(2),
        construction_cost: project_unit.base_rate - project_unit.land_rate,
        installment_percent: ps.installment_percent,
        basic_installment_amount: (project_unit.agreement_price * 10/100).round(2),
        tds_percent: (project_unit.agreement_price > 500000 ? 1 : 0),
        tds_amount: project_unit.tds_amount,
        amount_received: 0.0,
        infrastructure_charges: project_unit.city_infrastructure_fund.round(2),
        maintenance_deposit: project_unit.advance_maintenance_charges.round(2),
        power_supply: project_unit.wep_price.round(2),
        club_charges: project_unit.clubhouse_amenities_price.round(2),
        corpus_fund_charges: project_unit.corpus_fund.round(2),
        payment_schedule_type: ps.name
      }
      data << hash
    end
    data
  end
end
