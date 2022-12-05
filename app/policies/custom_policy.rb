class CustomPolicy < Struct.new(:user, :enable_users)
  include ApplicationHelper

  attr_reader :user, :current_client, :current_project, :current_domain

  def initialize(user_context, record)
    if user_context.is_a?(User)
      user = user_context
      @user = user
      @current_client = user.role?('superadmin') ? user.selected_client : user.booking_portal_client
      @current_project = nil
      @current_domain = nil
    else
      @user = user_context.user
      @current_client = user_context.current_client
      @current_project = user_context.current_project
      @current_domain = user_context.current_domain
    end
  end

  def add_booking?
    user.booking_portal_client.enable_actual_inventory?(user)
  end

  def inventory?(project = nil)
    if project.present?
      return false unless project.enable_inventory?
    end
    if user.role?(:channel_partner)
      user.role.in?(user.booking_portal_client.enable_actual_inventory) || (user.role.in?(user.booking_portal_client.enable_live_inventory) && user.enable_live_inventory)
    else
      ['superadmin', 'admin', 'sales_admin', 'sales', 'cp', 'cp_admin'].include?(user.role) && (user.role.in?(user.booking_portal_client.enable_actual_inventory) || user.role.in?(user.booking_portal_client.enable_live_inventory))
    end
  end

  def emails?
    EmailPolicy::Scope.new(user, Email).resolve
  end

  def smses?
    SmsPolicy::Scope.new(user, Sms).resolve
  end

  def audits?
    "#{user.buyer? ? 'Buyer' : 'Admin'}::Audit::RecordPolicy".constantize.new(user, Audit::Record.new).index?
  end

  def referrals?
    "#{user.buyer? ? 'Buyer' : 'Admin'}::ReferralPolicy".constantize.new(user, User).index?
  end

  def accounts?
    "#{user.buyer? ? 'Buyer' : 'Admin'}::AccountPolicy".constantize.new(user, Account).index?
  end

  def phases?
    "#{user.buyer? ? 'Buyer' : 'Admin'}::PhasePolicy".constantize.new(user, Phase).index?
  end

  def sync_logs?
    "#{user.buyer? ? 'Buyer' : 'Admin'}::SyncLogPolicy".constantize.new(user, SyncLog).index?
  end

  def erp_models?
    %w[superadmin].include?(user.role)
  end

  def schemes?
    "#{user.buyer? ? 'Buyer' : 'Admin'}::SchemePolicy".constantize.new(user, Scheme).index?
  end

  def incentive_schemes?
    "#{user.buyer? ? '' : 'Admin'}::IncentiveSchemePolicy".constantize.new(user, IncentiveScheme).index?
  end

  def variable_incentive_schemes?
    "#{user.buyer? ? '' : 'Admin'}::VariableIncentiveSchemePolicy".constantize.new(user, VariableIncentiveScheme).index?
  end

  def user_kycs?
    "#{user.buyer? ? 'Buyer' : 'Admin'}::UserKycPolicy".constantize.new(user, UserKyc).index?
  end

  def portal_stage_priorities?
    "#{user.buyer? ? '' : 'Admin::'}PortalStagePriorityPolicy".constantize.new(user, PortalStagePriority).index?
  end

  def user_requests?
    "#{user.buyer? ? '' : 'Admin::'}UserRequestPolicy".constantize.new(user, UserRequest).index?
  end

  # def channel_partners?
  #   "#{user.buyer? ? '' : 'Admin::'}ChannelPartnerPolicy".constantize.new(user, ChannelPartner).index?
  # end

  def checklists?
    "#{user.buyer? ? '' : 'Admin::'}ChecklistPolicy".constantize.new(user, Checklist).index?
  end

  def bulk_upload_reports?
    "#{user.buyer? ? '' : 'Admin::'}BulkUploadReportPolicy".constantize.new(user, BulkUploadReport).index?
  end

  def crms?
    "#{user.buyer? ? '' : 'Admin::'}Crm::BasePolicy".constantize.new(user, Crm::Base).index?
  end

  def api_logs?
    "#{user.buyer? ? '' : 'Admin::'}ApiLogPolicy".constantize.new(user, ApiLog).index?
  end

  def assets?
    "#{user.buyer? ? 'Buyer' : 'Admin'}::AssetPolicy".constantize.new(user, Asset).index?
  end

  def push_notifications?
    "#{user.buyer? ? '' : 'Admin::'}PushNotificationPolicy".constantize.new(user, PushNotification).index?
  end

  def meetings?
    "#{user.buyer? ? 'Buyer' : 'Admin'}::MeetingPolicy".constantize.new(user, Meeting).index?
  end

  # def announcements?
  #   "#{user.buyer? ? 'Buyer' : 'Admin'}::AnnouncementPolicy".constantize.new(user, Announcement).index?
  # end

  def sales_board?
    DashboardPolicy.new(user, User).sales_board?
  end

  def discounts?
    Admin::DiscountPolicy.new(user, Discount).index?
  end

  # def cp_lead_activities?
  #   "#{user.buyer? ? '' : 'Admin::'}CpLeadActivityPolicy".constantize.new(user, CpLeadActivity).index?
  # end

  def payment_types?
    "#{user.buyer? ? 'Buyer' : 'Admin'}::PaymentTypePolicy".constantize.new(user, PaymentType).index?
  end

  def invoices?
    Admin::InvoicePolicy.new(user, Invoice).index?
  end

  def meetings?
    "#{user.buyer? ? 'Buyer' : 'Admin'}::MeetingPolicy".constantize.new(user, Meeting).index?
  end

  def user_requests?
    "#{user.buyer? ? 'Buyer' : 'Admin'}::UserRequestPolicy".constantize.new(user, UserRequest).index?
  end

  def banner_assets?
    Admin::BannerAssetPolicy.new(user, BannerAsset).index?
  end

  def workflows?
    Admin::WorkflowPolicy.new(user, Workflow).index?
  end

  def self.custom_methods
    %w[schemes incentive_schemes emails smses referrals accounts checklists bulk_upload_reports crms api_logs push_notifications user_kycs sales_board variable_incentive_schemes discounts payment_types invoices meetings user_requests banner_assets workflows].sort
  end
end
