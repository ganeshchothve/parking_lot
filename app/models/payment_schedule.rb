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
  belongs_to :project_unit

  # Validations
  validates :name, :display_order, :land_cost, :construction_cost, :installment_percent, :basic_installment_amount, :tds_percent, :tds_amount, :amount_received, :infrastructure_charges, :maintenance_deposit, :power_supply, :club_charges, :corpus_fund_charges, :payment_schedule_type, presence: true


  # Data to be sent to SFDC
  def self.api_json(project_unit)
    data = []

    create_or_update_payment_schedules(project_unit)

    # keeping dynamic calculation here because it may happen that base_rate has changed after payment schedules are created.
    project_unit.payment_schedules.each do |ps|
      user = project_unit.user
      opp_id = user.lead_id + project_unit.sfdc_id
      hash = ps.as_json(only: [:name, :display_order, :status, :land_cost, :construction_cost, :installment_percent, :basic_installment_amount, :amount_received, :infrastructure_charges, :maintenance_deposit, :power_supply, :club_charges, :corpus_fund_charges])
      hash.merge!(
        'opp_id' => opp_id,
        'selldo_lead_id' => user.lead_id,
        'unit_sfdc_id' => project_unit.sfdc_id,
        'payment_schedule_id' => ps.id.to_s,
        'due_date' => project_unit.blocking_payment.created_at.strftime("%Y-%m-%d"),
        'tds_percent' => (project_unit.agreement_price > 500000 ? 1 : 0),
        'tds_amount' => project_unit.tds_amount,
        'payment_schedule_type' => ps.name
      )
      data << hash
    end
    data
  end


  private

  def self.create_or_update_payment_schedules(project_unit)
    payment_data = [
      { key: 'agreement', name: "On Booking/ Agreement", installment_percent: 10, display_order: 1 },
      { key: 'basement', name: "On completion of basement slab", installment_percent: 25, display_order: 2 },
      { key: 'slab_5', name: "On completion of 5th floor slab", installment_percent: 25, display_order: 3 },
      { key: 'slab_10', name: "On completion of 10th floor slab", installment_percent: 25, display_order: 4 },
      { key: 'completion', name: "On completion of painting & finishes and deposits (power + water)", installment_percent: 10, display_order: 5 },
      { key: 'possession', name: "On Possession + remaining additional deposits / charges + registration", installment_percent: 5, display_order: 6 }
    ]

    payment_data.each do |data|
      land_cost = calculate_percent(project_unit.land_price, data[:installment_percent]).round(2)
      construction_cost = calculate_percent(project_unit.construction_price, data[:installment_percent]).round(2)
      basic_installment_amount = land_cost + construction_cost
      infrastructure_charges = power_supply = club_charges = corpus_fund_charges = maintenance_deposit = 0
      if data[:key] == 'completion'
        power_supply = project_unit.wep_price.round(2)
      elsif data[:key] == 'possession'
        infrastructure_charges = project_unit.city_infrastructure_fund.round(2)
        club_charges = project_unit.clubhouse_amenities_price.round(2)
        corpus_fund_charges = project_unit.corpus_fund.round(2)
        maintenance_deposit = project_unit.advance_maintenance_charges.round(2)
      end

      hash = {
        "name" => data[:name],
        "display_order" => data[:display_order],
        "status" => "Pending",
        "due_date" => nil,
        "land_cost" => land_cost,
        "construction_cost" => construction_cost,
        "installment_percent" => data[:installment_percent],
        "basic_installment_amount" => basic_installment_amount,
        "tds_percent" => project_unit.agreement_price.to_i > 500000 ? 1 : 0,
        "tds_amount" => calculate_percent(calculate_percent(project_unit.agreement_price, 25), 1).round(2),
        "amount_received" => 0.0,
        "infrastructure_charges" => infrastructure_charges,
        "maintenance_deposit" => maintenance_deposit,
        "power_supply" => power_supply,
        "club_charges" => club_charges,
        "corpus_fund_charges" => corpus_fund_charges,
        "payment_schedule_type" => data[:name]
      }
      if project_unit.payment_schedules.empty?
        project_unit.payment_schedules.create!(hash)
      else
        project_unit.payment_schedules.where(name: data[:name]).first.try(:update_attributes, hash)
      end
    end
  end

  def self.calculate_percent(amount, percent)
    amount = amount * percent/100 
    amount.round
  end
end
