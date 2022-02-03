class BookingDetail
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable
  include InsertionStringMethods
  include BookingDetailStateMachine
  # include SyncDetails
  include Tasks
  include ApplicationHelper
  extend FilterByCriteria
  extend RenderAnywhere
  include PriceCalculator
  include CrmIntegration
  include IncentiveSchemeAutoApplication

  THIRD_PARTY_REFERENCE_IDS = %w(reference_id)
  STATUSES = %w[hold blocked booked_tentative booked_confirmed under_negotiation scheme_rejected scheme_approved swap_requested swapping swapped swap_rejected cancellation_requested cancelling cancelled cancellation_rejected]
  BOOKING_STAGES = %w[blocked booked_tentative booked_confirmed under_negotiation scheme_approved]
  DOCUMENT_TYPES = %w[booking_detail_form document]

  field :status, type: String
  field :erp_id, type: String, default: ''
  field :name, type: String
  field :base_rate, type: Float, default: 0
  field :floor_rise, type: Float, default: 0
  field :saleable, type: Float, default: 0
  field :project_name, type: String
  field :project_tower_name, type: String
  field :booking_project_unit_name, type: String
  field :project_unit_configuration, type: String
  field :bedrooms, type: String
  field :bathrooms, type: String
  field :carpet, type: Float
  field :agreement_price, type: Integer
  field :other_costs, type: Integer
  field :all_inclusive_price, type: Integer
  field :booked_on, type: Date
  field :agreement_date, type: Date
  field :tentative_agreement_date, type: Date
  field :ladder_stage, type: Array
  field :source, type: String

  mount_uploader :tds_doc, DocUploader

  enable_audit(
    indexed_fields: %i[manager_id project_unit_id],
    audit_fields: %i[manager_id status manager_id project_unit_id user_id user_kyc_ids],
    reference_ids_without_associations: [
      { field: 'manager_id', klass: 'ChannelPartner' },
      { field: 'primary_user_kyc_id', klass: 'UserKyc' }
    ]
  )

  embeds_many :costs, as: :costable
  embeds_many :data, as: :data_attributable
  embeds_many :tasks, cascade_callbacks: true
  belongs_to :project#, optional: true
  belongs_to :project_tower, optional: true
  belongs_to :project_unit, optional: true
  belongs_to :lead, optional: true
  belongs_to :user, optional: true
  belongs_to :manager, class_name: 'User', optional: true
  belongs_to :channel_partner, optional: true
  belongs_to :cp_manager, class_name: 'User', optional: true
  belongs_to :cp_admin, class_name: 'User', optional: true
  belongs_to :search, optional: true
  # When a new booking detail object is created from another object, this field will be set. This happens when the user creates a swap request.
  belongs_to :parent_booking_detail, class_name: 'BookingDetail', optional: true
  belongs_to :primary_user_kyc, class_name: 'UserKyc', optional: true, validate: true
  belongs_to :incentive_scheme, optional: true
  has_many :assets, as: :assetable
  has_many :receipts, dependent: :nullify
  has_many :smses, as: :triggered_by, class_name: 'Sms'
  has_many :booking_detail_schemes, dependent: :destroy
  has_many :notes, as: :notable
  has_many :user_requests, as: :requestable
  has_many :related_booking_details, foreign_key: :parent_booking_detail_id, primary_key: :_id, class_name: 'BookingDetail'
  has_many :invoices, as: :invoiceable
  has_and_belongs_to_many :user_kycs, validate: true
  belongs_to :channel_partner, optional: true
  belongs_to :creator, class_name: 'User', optional: true
  belongs_to :account_manager, class_name: 'User', optional: true
  belongs_to :site_visit, optional: true

  # TODO: uncomment
  # validates :name, presence: true
  validates :status, presence: true
  validates :erp_id, uniqueness: true, allow_blank: true
  validate :kyc_mandate
  validate :validate_content, on: :create
  validates :primary_user_kyc, :receipts, :tasks, copy_errors_from_child: true, allow_blank: true
  validates :agreement_date, presence: true, if: proc { booked_tentative? && status_was == 'blocked' }, unless: proc { project_unit.present? }

  delegate :name, :blocking_amount, to: :project_unit, prefix: true, allow_nil: true
  delegate :name, :email, :phone, to: :user, prefix: true, allow_nil: true
  delegate :name, :email, :phone, :role, :role?, to: :manager, prefix: true, allow_nil: true

  default_scope -> { desc(:created_at) }

  scope :filter_by_id, ->(_id) { where(_id: _id) }
  scope :filter_by_name, ->(name) { where(name: ::Regexp.new(::Regexp.escape(name), 'i')) }
  scope :filter_by_status, ->(status) do
    if status.is_a?(Array)
      where(status: {"$in": status})
    else
      where(status: status)
    end
  end
  scope :filter_by_statuses, ->(statuses) { where(status: {"$in": statuses}) }
  scope :filter_by_project_id, ->(project_id) { where(project_id: project_id) }
  scope :filter_by_project_ids, ->(project_ids){ project_ids.present? ? where(project_id: {"$in": project_ids}) : all }
  scope :filter_by_project_tower_id, ->(project_tower_id) { where(project_unit_id: { "$in": ProjectUnit.where(project_tower_id: project_tower_id).pluck(:_id) })}
  scope :filter_by_user_id, ->(user_id) { where(user_id: user_id)  }
  scope :filter_by_lead_id, ->(lead_id){ where(lead_id: lead_id)}
  scope :filter_by_manager_id, ->(manager_id){ where(manager_id: manager_id) }
  scope :filter_by_cp_manager_id, ->(cp_manager_id){ where(cp_manager_id: cp_manager_id) }
  scope :filter_by_incentive_scheme_id, ->(incentive_scheme_id){ where(incentive_scheme_id: incentive_scheme_id) }
  scope :filter_by_ladder_stage, ->(stage) { where(ladder_stage: stage.to_i) }
  scope :filter_by_tasks_completed, ->(task) { where(tasks: { '$elemMatch': {key: task, completed: true} }) }
  scope :filter_by_tasks_pending, ->(task) { where(tasks: { '$elemMatch': { key: task, completed: {'$ne': true} } }) }
  scope :filter_by_tasks_completed_tracked_by, ->(tracked_by) { where("#{tracked_by}_tasks_completed": true) }
  scope :filter_by_tasks_pending_tracked_by, ->(tracked_by) { where("#{tracked_by}_tasks_completed": false) }
  scope :filter_by_search, ->(search) { regex = ::Regexp.new(::Regexp.escape(search), 'i'); where(name: regex ) }
  scope :filter_by_created_at, ->(date) { start_date, end_date = date.split(' - '); where(created_at: Date.parse(start_date).beginning_of_day..Date.parse(end_date).end_of_day) }
  scope :filter_by_booked_on, ->(date) { start_date, end_date = date.split(' - '); where(booked_on: Date.parse(start_date).beginning_of_day..Date.parse(end_date).end_of_day)
  }
  scope :filter_by_agreement_date, ->(date) { start_date, end_date = date.split(' - '); where(agreement_date: Date.parse(start_date).beginning_of_day..Date.parse(end_date).end_of_day)
  }

  scope :incentive_eligible, ->(category) do
    case category
    when 'spot_booking'
      blocked
    when 'brokerage'
      booked_confirmed.filter_by_tasks_completed_tracked_by('system')
    else
      all.not_eligible
    end
  end
  scope :booking_stages, -> { all.in(status: BOOKING_STAGES) }

  accepts_nested_attributes_for :notes, :tasks, :receipts, :user_kycs, :primary_user_kyc, reject_if: :all_blank

  def validate_content
    _file = tds_doc.file
    file_name = _file.try(:original_filename)
    if file_name.present?
      self.errors.add(:base, 'Invalid file name/type (The filename should not have more than one dot (.))') if file_name.split('.').length > 2
      self.errors.add(:base, 'File without name provided') if file_name.split('.')[0].blank?
      file_meta = MimeMagic.by_magic(open(tds_doc.path)) rescue nil
      self.errors.add(:base, 'Invalid file (you can only upload jpg|png|jpeg|pdf files)') if ( file_meta.nil? || %w[png jpg jpeg pdf PNG JPG PDF JPEG].exclude?(file_meta.subtype) )
    end
  end

  def send_notification!
    message = "#{primary_user_kyc.name} just booked apartment #{project_unit.name} in #{project_unit.project_tower_name}"
    Gamification::PushNotification.new.push(message) if Rails.env.staging? || Rails.env.production?
  end

  def booking_detail_scheme=(bds)
    @booking_detail_scheme = bds
  end

  def booking_detail_scheme
    @booking_detail_scheme ||= booking_detail_schemes.in(status: ['approved', 'draft']).first
  end

  def sync(erp_model, sync_log)
    Api::BookingDetailsSync.new(erp_model, self, sync_log).execute
  end

  def is_registration_done?
    self.tasks.where(key: 'registration_done').first.try(:completed?) || false
  end

  #
  # Unit Auto Release is set on when unit moved form hold stage. This Auto release set as Todays date plus client blocking allows date. That time inform client about auto relase date.
  #
  #
  # @return [Email Object]
  #
  def auto_released_extended_inform_buyer!
    template = Template::EmailTemplate.find_by(project_id: project_id, name: "auto_release_on_extended")
    email = Email.create!({
      project_id: project_id,
      booking_portal_client_id: project_unit.booking_portal_client_id,
      email_template_id: template.id,
      cc: project_unit.booking_portal_client.notification_email.to_s.split(',').map(&:strip),
      recipients: [ lead.user ],
      cc_recipients: ( lead.manager_id.present? ? [lead.manager] : [] ),
      triggered_by_id: self.id,
      triggered_by_type: self.class.to_s
    })
    email.sent!
  end

  def send_cost_sheet_and_payment_schedule(lead)
    if project_unit.booking_portal_client.email_enabled?
      attachments_attributes = []
      cost_details = self.class.render_anywhere('admin/project_units/cost_sheet_and_payment_schedule', { booking_detail: self }, 'layouts/pdf')
      pdf = WickedPdf.new.pdf_from_string(cost_details.presence)
      File.open("#{Rails.root}/exports/#{project_unit.name}_cost_sheet.pdf", "wb") do |file|
        file << pdf
      end
      attachments_attributes << {file: File.open("#{Rails.root}/exports/#{project_unit.name}_cost_sheet.pdf")}
      email_template = Template::EmailTemplate.find_by(project_id: project_id, name: "cost_sheet_and_payment_schedule")
      email = Email.create!({
        project_id: project_id,
        booking_portal_client_id: project_unit.booking_portal_client_id,
        body: ERB.new(project_unit.booking_portal_client.email_header).result(binding) + email_template.parsed_content(self) + ERB.new(project_unit.booking_portal_client.email_footer).result(binding),
        subject: email_template.parsed_subject(self),
        cc: project_unit.booking_portal_client.notification_email.to_s.split(',').map(&:strip),
        recipients: [lead.user],
        cc_recipients: [],
        triggered_by_id: self.id,
        triggered_by_type: self.class.to_s,
        attachments_attributes: attachments_attributes
      })
      email.sent!
    end
  end

  def ds_name
    "#{name} - #{I18n.t("mongoid.attributes.booking_detail/status.#{status}")}"
  end

  alias :resource_name :ds_name
  # Used in incentive invoice
  alias :name_in_invoice :name
  alias :invoiceable_manager :manager
  alias :invoiceable_date :booked_on

  def invoiceable_price
    calculate_invoice_agreement_amount
  end

  # Find incentive scheme
  def find_incentive_schemes(category)
    tower_id = project_tower_id
    tier_id = manager&.tier_id
    incentive_schemes = ::IncentiveScheme.approved.where(resource_class: self.class.to_s, category: category, project_id: project_id, auto_apply: true).lte(starts_on: invoiceable_date).gte(ends_on: invoiceable_date)
    # Find tier level scheme
    if tier_id
      _incentive_schemes = (incentive_schemes.where(project_tower_id: tower_id, tier_id: tier_id) || incentive_schemes.where(tier_id: tier_id, project_tower_id: nil))
    end
    # Find tower level scheme
    _incentive_schemes = _incentive_schemes.presence || incentive_schemes.where(project_tower_id: tower_id, tier_id: nil)
    # Find project level scheme
    _incentive_schemes = _incentive_schemes.presence || incentive_schemes.where(project_tower_id: nil, tier_id: nil)
    # Use default scheme if not found any of above
    #_incentive_schemes.presence ||= ::IncentiveScheme.where(default: true)
    _incentive_schemes
  end

  # Find all the bookings for a channel partner that fall under this scheme
  def find_all_resources_for_scheme(i_scheme)
    booking_details = self.class.incentive_eligible(i_scheme.category).where(project_id: i_scheme.project_id, :"incentive_scheme_data.#{i_scheme.id.to_s}".exists => true, manager_id: self.manager_id).gte(booked_on: i_scheme.starts_on).lte(booked_on: i_scheme.ends_on)
    booking_details = booking_details.where(project_tower_id: i_scheme.project_tower_id) if i_scheme.project_tower_id.present?
    self.class.or(booking_details.selector, {id: self.id})
  end

  # validates kyc presence if booking is not allowed without kyc
  def kyc_mandate
    if project_unit.present? && project.enable_booking_with_kyc && !primary_user_kyc_id.present?
      self.errors.add(:base, "KYC is mandatory for booking.")
    end
  end


  def ageing
    _receipts = self.receipts.in(status:["clearance_pending", "success"]).asc(:created_at)
    if(["booked_confirmed"].include?(self.status))
      due_since = _receipts.first.created_at.to_date rescue self.created_at.to_date
      last_booking_payment = _receipts.last.created_at.to_date rescue Date.today
      age = (last_booking_payment - due_since).to_i
    elsif(["blocked", "booked_tentative"].include?(self.status))
      due_since = _receipts.first.created_at.to_date rescue self.created_at.to_date
      age = (Date.today - due_since).to_i
    else
      return "NA"
    end
    if age < 15
      return "< 15 days"
    elsif age < 30
      return "< 30 days"
    elsif age < 45
      return "< 45 days"
    elsif age < 60
      return "< 60 days"
    else
      return "> 60 days"
    end
  end

  def cost_sheet_template(booking_detail_scheme_id = nil)
    bds = booking_detail_scheme_id.present? ? booking_detail_schemes.where(id: booking_detail_scheme_id).first : booking_detail_scheme
    bds.try(:cost_sheet_template)
  end

  def payment_schedule_template(booking_detail_scheme_id = nil)
    bds = booking_detail_scheme_id.present? ? booking_detail_schemes.where(id: booking_detail_scheme_id).first : booking_detail_scheme
    bds.try(:payment_schedule_template)
  end

  def total_amount_paid
    receipts.success.sum(:total_amount)
  end

  def pending_balance(options={})
    strict = options[:strict] || false
    lead_id = options[:lead_id] || self.lead_id
    return unless self.project_unit.present?
    if lead_id.present?
      receipts_total = Receipt.where(lead_id: lead_id, booking_detail_id: self.id)
      if strict
        receipts_total = receipts_total.where(status: "success")
      else
        receipts_total = receipts_total.in(status: ['clearance_pending', "success"])
      end
      receipts_total = receipts_total.sum(:total_amount)
      return (self.project_unit.booking_price - receipts_total)
    else
      return self.project_unit.booking_price
    end
  end

  def booking_number
    receipts.asc(:created_at).first.try(:receipt_id) || name
  end

  def send_booking_form_to_sign
    _user = self.lead.user
    booking_detail_form = self.class.render_anywhere('templates/booking_detail_form', { booking_detail: self }, 'layouts/pdf')
    pdf = WickedPdf.new.pdf_from_string(booking_detail_form.presence)
    asset = self.assets.new(document_type: 'booking_detail_form')
    File.open("#{Rails.root}/exports/#{booking_number}_to_sign_booking_form.pdf", "wb") do |file|
      file << pdf
      asset.file = file
    end
    if asset.save && %w[staging production].include?(Rails.env)
      options = { request_name: "#{self.class.to_s}-#{self.id.to_s}", recipient_name: _user.name, recipient_email: _user.email }
      DocumentSignn::ZohoSign::DocumentCreateWorker.perform_async(_user.booking_portal_client.document_sign.id.to_s, asset.id.to_s, options)
    end
  end

  def send_booking_detail_form_mail_and_sms
    if project_unit.booking_portal_client.email_enabled?
      attachments_attributes = []
      booking_detail_form = self.class.render_anywhere('templates/booking_detail_form', { booking_detail: self }, 'layouts/pdf')
      pdf = WickedPdf.new.pdf_from_string(booking_detail_form.presence)
      File.open("#{Rails.root}/exports/#{booking_number}_booking_form.pdf", "wb") do |file|
        file << pdf
      end
      attachments_attributes << {file: File.open("#{Rails.root}/exports/#{booking_number}_booking_form.pdf")}
      email = Email.create!({
        project_id: project_id,
        booking_portal_client_id: project_unit.booking_portal_client_id,
        email_template_id: Template::EmailTemplate.find_by(project_id: project_id, name: "booking_confirmed").id,
        recipients: [lead.user],
        cc: project_unit.booking_portal_client.notification_email.to_s.split(',').map(&:strip),
        cc_recipients: [],
        triggered_by_id: self.id,
        triggered_by_type: self.class.to_s,
        attachments_attributes: attachments_attributes
      })
      email.sent!
    end
    if project_unit.booking_portal_client.sms_enabled?
      template = Template::SmsTemplate.find_by(project_id: project_id, name: "booking_confirmed")
      sms = Sms.create!(
        project_id: project_id,
        booking_portal_client_id: project_unit.booking_portal_client_id,
        recipient_id: lead.user_id,
        sms_template_id: template.id,
        triggered_by_id: self.id,
        triggered_by_type: self.class.to_s
      )
    end
  end

  def incentive_eligible?(category=nil)
    if category.present?
      case category
      when 'spot_booking'
        blocked?
      when 'brokerage'
        if project.present?
          if project.enable_inventory?
            if project_unit.present?
              blocked?
            else
              false
            end
          else
            blocked?
          end
        end
      else
        false
      end
    else
      _actual_incentive_eligible?
    end
  end

  def actual_incentive_eligible?(category=nil)
    if category.present?
      case category
      when 'spot_booking'
        blocked?
      when 'brokerage'
        if project.present?
          if project.enable_inventory?
            if project_unit.present?
              booked_confirmed? && system_tasks_completed?
            else
              false
            end
          else
            booked_confirmed?
          end
        end
      else
        false
      end
    else
      _actual_incentive_eligible?
    end
  end

  def calculate_invoice_agreement_amount
    if self.project.enable_inventory? && self.project_unit.present?
      self.calculate_agreement_price
    else
      (self.agreement_price)
    end
  end

  class << self

    def user_based_scope(user, params = {})
      custom_scope = {}
      if params[:lead_id].blank? && !user.buyer?
        case user.role.to_s
        when 'channel_partner'
          custom_scope = { manager_id: user.id, channel_partner_id: user.channel_partner_id, project_id: { '$in': user.interested_projects.approved.distinct(:project_id) } }
        when 'cp_owner'
          custom_scope = { channel_partner_id: user.channel_partner_id }
        when 'cp_admin'
          #cp_ids = User.where(role: 'cp', manager_id: user.id).distinct(:id)
          #channel_partner_ids = User.where(role: 'channel_partner', manager_id: {"$in": cp_ids}).distinct(:id)
          #custom_scope = { manager_id: { "$in": channel_partner_ids } }
          custom_scope = { cp_admin_id: user.id }
        when 'cp'
          #channel_partner_ids = User.where(role: 'channel_partner').where(manager_id: user.id).distinct(:id)
          #custom_scope = { manager_id: { "$in": channel_partner_ids } }
          custom_scope = { cp_manager_id: user.id }
        when 'account_manager'
         custom_scope = { creator_id: user.id }
        when 'account_manager_head'
         custom_scope = { project_unit_id: nil }
        when 'billing_team'
         # custom_scope = { project_unit_id: nil, status: { '$nin': %w(blocked) } }
        end
      end

      custom_scope = { lead_id: params[:lead_id] } if params[:lead_id].present?
      custom_scope = { user_id: user.id, lead_id: user.selected_lead_id } if user.buyer?

      unless user.role.in?(User::ALL_PROJECT_ACCESS + User::BUYER_ROLES + %w(channel_partner))
        custom_scope.merge!({project_id: {"$in": Project.all.pluck(:id)}})
      end
      custom_scope
    end

    def user_based_available_statuses(user)
      if user.present?
        if user.role?('billing_team')
           %w[booked_confirmed booked_tentative cancelled]
        elsif user.role?('account_manager') || user.role?('account_manager_head')
           %w[blocked booked_tentative booked_confirmed cancelled]
        else
          BookingDetail.aasm.states.map(&:name)
        end
      else
        BookingDetail.aasm.states.map(&:name)
      end
    end
  end
end
