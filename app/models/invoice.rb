class Invoice
  include Mongoid::Document
  include Mongoid::Timestamps
  include InsertionStringMethods
  include InvoiceStateMachine
  extend FilterByCriteria
  include CrmIntegration
  # include NumberIncrementor

  DOCUMENT_TYPES = []
  INVOICE_REPORT_STAGES = %w(draft raised pending_approval approved tax_invoice_raised paid)
  PAYOUT_DASHBOARD_STAGES = %w(draft raised pending_approval approved paid)
  INVOICE_EVENTS = Invoice.aasm.events.map(&:name)

  field :amount, type: Float, default: 0.0
  field :gst_amount, type: Float, default: 0.0
  field :status, type: String, default: 'tentative'
  field :raised_date, type: DateTime
  field :processing_date, type: DateTime
  field :approved_date, type: DateTime
  field :paid_date, type: DateTime
  field :rejection_reason, type: String
  field :comments, type: String
  field :net_amount, type: Float
  field :gst_slab, type: Float
  field :agreement_amount, type: Float, default: 0.0
  #field :percentage_slab, type: Float, default: 18
  field :number, type: String
  field :category, type: String
  field :brokerage_type, type: String, default: 'sub_brokerage'
  field :payment_to, type: String, default: 'channel_partner'

  belongs_to :invoiceable, polymorphic: true
  belongs_to :project, optional: true
  belongs_to :manager, class_name: 'User', optional: true
  belongs_to :channel_partner, optional: true
  belongs_to :cp_manager, class_name: 'User', optional: true
  belongs_to :cp_admin, class_name: 'User', optional: true
  belongs_to :creator, class_name: 'User'
  belongs_to :account_manager, class_name: 'User', optional: true
  belongs_to :user, optional: true
  belongs_to :lead, optional: true
  has_one :incentive_deduction
  has_many :assets, as: :assetable
  embeds_one :cheque_detail
  embeds_one :payment_adjustment, as: :payable

  validates :category, :brokerage_type, :payment_to, presence: true
  validates :number, presence: true, if: proc { raised? && category.in?(%w(brokerage)) }
  validates :rejection_reason, presence: true, if: :rejected?
  validates :comments, presence: true, if: proc { pending_approval? && status_was == 'rejected' }
  validates :amount, numericality: { greater_than: 0 }
  # validates :cheque_detail, presence: true, if: :paid?
  # validates :cheque_detail, copy_errors_from_child: true, if: :cheque_detail?
  validates :net_amount, numericality: { greater_than: 0 }, if: :approved?
  validates :project_id, presence: true, if: proc { invoiceable_type != 'User' }

  delegate :name, to: :project, prefix: true, allow_nil: true
  delegate :name, to: :manager, prefix: true, allow_nil: true

  scope :filter_by_invoice_type, ->(request_type){ where(_type: /#{request_type}/i)}
  scope :filter_by_status, ->(status) { where(status: status) }
  scope :filter_by_category, ->(category) do
    if (category.is_a?(Array) && !(category == ["all"]))
      where(category: {"$in": category})
    elsif(category == ["all"])
      where(category: {"$in": IncentiveScheme::CATEGORIES})
    else
      where(category: category)
    end
  end
  scope :filter_by_project_id, ->(project_id) { where(project_id: project_id) }
  scope :filter_by_customer_id, ->(customer_id) { where(customer_id: customer_id) }
  scope :filter_by_lead_id, ->(lead_id) { where(lead_id: lead_id) }
  scope :filter_by_project_ids, ->(project_ids){ project_ids.present? ? where(project_id: {"$in": project_ids}) : all }
  scope :filter_by_manager_id, ->(manager_id) { where(manager_id: manager_id) }
  scope :filter_by_channel_partner_id, ->(channel_partner_id) { where(channel_partner_id: channel_partner_id) }
  scope :filter_by_created_at, ->(date) { start_date, end_date = date.split(' - '); where(created_at: (Date.parse(start_date).beginning_of_day)..(Date.parse(end_date).end_of_day)) }
  scope :filter_by_invoiceable_id, ->(invoiceable_id) { where(invoiceable_id: invoiceable_id) }
  scope :filter_by_number, ->(number) { where(number: number) }
  scope :filter_by_categories, ->(categories) { where(category: {"$in": categories}) }
  scope :filter_by_raised_date, ->(date) { start_date, end_date = date.split(' - '); where(raised_date: Date.parse(start_date).beginning_of_day..Date.parse(end_date).end_of_day) }

  #this filter use for Payout dashboard
  scope :filter_by_payout_status, ->(status) do
    case status
    when "invoiced"
      where('$or': [{category: "brokerage", status: {"$in": ["raised"]}}, {category: {"$in": ["spot_booking", "walk_in"]}, status: {"$in": ["draft"]}}])
    when "waiting_for_registration"
      where(category: "brokerage", status: "tentative")
    when "waiting_for_invoicing"
      where(category: "brokerage", status: "draft")
    when "paid"
      where(status: "paid")
    when "cancellation"
      where(category: "brokerage",status: "rejected")
    end
  end

  accepts_nested_attributes_for :cheque_detail, reject_if: proc { |attrs| attrs.except('creator_id').values.all?(&:blank?) }
  accepts_nested_attributes_for :payment_adjustment, reject_if: proc { |attrs| attrs['absolute_value'].blank? }

  def calculated?
    _type.match(/calculated/i)
  end

  def manual?
    _type.match(/manual/i)
  end

  def generate_pdf
    unless self.assets.where(asset_type: 'system_generated_invoice').present?
      pdf_content = ApplicationMailer.test(body: self.project.booking_portal_client.templates.where(_type: "Template::InvoiceTemplate", project_id: self.project_id).first.parsed_content(self))
      pdf = WickedPdf.new.pdf_from_string(pdf_content.html_part.body.to_s)
      asset = self.assets.build(asset_type: 'system_generated_invoice', assetable: self, assetable_type: self.class.to_s)
      File.open("#{Rails.root}/exports/invoice-#{self.id}.pdf", "wb") do |file|
        file << pdf
        asset.file = file
      end
      asset.save
    end
  end

  def calculate_gst_amount
    if self.project&.gst_slab_applicable?
      (amount * ((gst_slab || 0)/100)).round(2)
    else
      0
    end
  end

  def get_payout_status
    if (category == "brokerage" && raised?) || (["spot_booking", "walk_in"].include?(category) && ["approved","raised","draft"].include?(status))
      "Invoiced"
    elsif (category == "brokerage" && tentative?)
      "Waiting for Registration"
    elsif (category == "brokerage" && draft?)
      "Waiting for Invoicing"
    elsif paid?
      "Paid"
    elsif rejected?
      "Cancellation"
    end
  end

  def self.available_payout_statuses
    [
      { id: 'invoiced', text: 'Invoiced' },
      { id: 'waiting_for_registration', text: 'Waiting for Registration' },
      { id: 'waiting_for_invoicing', text: 'Waiting for Invoicing' },
      { id: 'paid', text: 'Paid' },
      { id: 'cancellation', text: 'Cancellation' }
    ]
  end

  def self.available_payout_categories
    [
      { id: 'all', text: 'All' },
      { id: 'walk_in', text: 'Site Visits' },
      { id: 'spot_booking', text: 'Spot Bookings' },
      { id: 'brokerage', text: 'Brokerage' },
    ]
  end

  def self.available_sort_options
    [
      { id: 'created_at.asc', text: 'Created - Oldest First' },
      { id: 'created_at.desc', text: 'Created - Newest First' },
      { id: 'raised_date.asc', text: 'Invoiced Date - Oldest First' },
      { id: 'raised_date.desc', text: 'Invoiced Date- Newest First' },
      { id: 'net_amount.asc', text: 'Amount - Low to High' },
      { id: 'net_amount.desc', text: 'Amount- High to Low' }
    ]
  end

  def calculate_net_amount
    _amount = amount + calculate_gst_amount
    _amount += payment_adjustment.try(:absolute_value).to_i if payment_adjustment.try(:absolute_value).present?
    _amount -= incentive_deduction.try(:amount).to_i if incentive_deduction.try(:approved?)
    _amount.round(2)
  end

  class << self
    def user_based_scope(user, params = {})
      custom_scope = {}
      if params[:invoiceable_id].blank? && !user.buyer?
        if user.role?('channel_partner')
          custom_scope = { manager_id: user.id, channel_partner_id: user.channel_partner_id, project_id: { '$in': user.interested_projects.approved.distinct(:project_id) }, status: { '$nin': %w(tentative) }}
        elsif user.role?('cp_owner')
          custom_scope = { channel_partner_id: user.channel_partner_id, status: { '$nin': %w(tentative) }  }
        elsif user.role?('billing_team')
          custom_scope = { status: { '$in': %w(tentative raised pending_approval approved rejected draft tax_invoice_raised paid) } }
        elsif user.role?('cp_admin')
          custom_scope = { cp_admin_id: user.id, status: { '$nin': %w(draft tentative) } }
          #custom_scope = { status: { '$nin': %w(draft raised) } }
        elsif user.role?('cp')
          custom_scope = { cp_manager_id: user.id, status: { '$nin': %w(tentative) } }
        elsif user.role?('account_manager')
          custom_scope = { account_manager_id: user.id, status: { '$nin': %w(tentative) } }
        elsif user.role.in?(%w(admin superadmin))
          custom_scope = { status: { '$in': %w(tentative raised pending_approval approved rejected draft tax_invoice_raised paid) } }
        else
          custom_scope = { status: { '$nin': %w(tentative) } }
        end
      end
      if params[:invoiceable_id].present?
        custom_scope = { invoiceable_id: params[:invoiceable_id] }
      end
      custom_scope = {} if user.buyer?

      unless user.role.in?(User::ALL_PROJECT_ACCESS + %w(channel_partner))
        custom_scope.merge!({project_id: {"$in": Project.all.pluck(:id)}})
      end
      custom_scope
    end

    def user_based_available_statuses(user)
      if user.present?
        if user.role?('billing_team')
          %w[raised pending_approval approved rejected draft tax_invoice_raised paid]
        elsif user.role?('cp_admin')
          Invoice.aasm.states.map(&:name) - [:draft, :raised]
        else
          Invoice.aasm.states.map(&:name)
        end
      else
        Invoice.aasm.states.map(&:name)
      end
    end
  end
end
