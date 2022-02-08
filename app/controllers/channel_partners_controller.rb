class ChannelPartnersController < ApplicationController
  include ChannelPartnerRegisteration

  before_action :authenticate_user!, except: %i[new create find_or_create_cp_user add_user_account], unless: proc { params[:action] == 'index' && params[:ds] == 'true' }
  before_action :set_channel_partner, only: %i[show edit update destroy change_state asset_form]
  around_action :apply_policy_scope, only: :index, unless: proc { params[:ds] == 'true' }
  before_action :authorize_resource, except: [:new, :create, :find_or_create_cp_user, :add_user_account]
  skip_before_action :verify_authenticity_token, only: [:find_or_create_cp_user]

  def index
    @channel_partners = ChannelPartner.build_criteria params
    @channel_partners = @channel_partners.paginate(page: params[:page], per_page: params[:per_page])
  end

  def show
    @resource = @channel_partner
  end

  def export
    if Rails.env.development?
      ChannelPartnerExportWorker.new.perform(current_user.id.to_s, params[:fltrs])
    else
      ChannelPartnerExportWorker.perform_async(current_user.id.to_s, params[:fltrs].as_json, timezone: Time.zone.name)
    end
    flash[:notice] = 'Your export has been scheduled and will be emailed to you in some time'
    redirect_to channel_partners_path(fltrs: params[:fltrs].as_json)
  end

  def new
    @user = User.new(role: 'cp_owner')
    render layout: 'landing_page'
  end

  def new_channel_partner
    @channel_partner = ChannelPartner.new(referral_code: params[:custom_referral_code])
    @channel_partner_id = @channel_partner.id
    @lead_id = params[:lead_id]
    render layout: false
  end

  def edit
    render layout: false
  end

  # POST
  def create_channel_partner
    @channel_partner_id = BSON::ObjectId(params[:channel_partner][:company_name]) rescue nil
    @channel_partner = ChannelPartner.where(id: @channel_partner_id).first if @channel_partner_id
    query = []
    query << { phone: params.dig(:channel_partner, :phone) } if params.dig(:channel_partner, :phone).present?
    query << { email: params.dig(:channel_partner, :email) } if params.dig(:channel_partner, :email).present?
    @cp_user = User.in(role: %w(channel_partner cp_owner)).or(query).first
    if @cp_user.present?
      if !@cp_user.is_active?
        if @channel_partner.blank?
          # Create Channel partner company if blank & put cp_user under it
          @channel_partner = ChannelPartner.new(permitted_attributes([:admin, ChannelPartner.new]))
          @channel_partner.assign_attributes(srd: cookies[:srd]) if cookies[:srd].present?
          respond_to do |format|
            if @channel_partner.save
              cookies.delete :srd
              format.html { redirect_to (user_signed_in? ? channel_partners_path : cp_signed_up_with_inactive_account_path(user_id: @cp_user.id)), notice: 'Registration Successfull' }
              format.json { render json: @channel_partner, status: :created }
            else
              flash.now[:alert] = @channel_partner.errors.full_messages.uniq
              format.html { render :new, status: :unprocessable_entity}
              format.json { render json: { errors: @channel_partner.errors.full_messages.uniq }, status: :unprocessable_entity }
            end
          end
        else @cp_user.channel_partner_id != @channel_partner.id
          # Do not allow to change company on inactive cp accounts through registration. Only owner of respective companies can add such accounts under a company.
          @cp_owner = User.cp_owner.where(channel_partner_id: @channel_partner.id).first
          @channel_partner = ChannelPartner.new(permitted_attributes([:admin, ChannelPartner.new]))
          respond_to do |format|
            err_msg = t('controller.channel_partners.create.not_allowed_message', owner_name: @cp_owner&._name || 'Admin')
            flash.now[:alert] = err_msg
            format.html { render :new, status: :unprocessable_entity}
            format.json { render json: { errors: err_msg }, status: :unprocessable_entity }
          end
        end
      else
        @channel_partner = ChannelPartner.new(permitted_attributes([:admin, ChannelPartner.new]))
        respond_to do |format|
          err_msg = t('controller.channel_partners.create.already_present_and_active_msg', company_name: @cp_user.channel_partner&.company_name)
          flash.now[:alert] = err_msg
          format.html { render :new, status: :unprocessable_entity}
          format.json { render json: { errors: err_msg }, status: :unprocessable_entity }
        end
      end
    else
      if @channel_partner.blank?
        @channel_partner = ChannelPartner.new(permitted_attributes([:admin, ChannelPartner.new]))
        @channel_partner.assign_attributes(srd: cookies[:srd]) if cookies[:srd].present?
        respond_to do |format|
          if @channel_partner.save
            cookies.delete :srd
            format.html { redirect_to (user_signed_in? ? channel_partners_path : signed_up_path(user_id: @channel_partner.users.first&.id)), notice: 'Channel partner was successfully created.' }
            format.json { render json: @channel_partner, status: :created }
          else
            flash.now[:alert] = @channel_partner.errors.full_messages.uniq
            format.html { render :new, status: :unprocessable_entity}
            format.json { render json: { errors: @channel_partner.errors.full_messages.uniq }, status: :unprocessable_entity }
          end
        end
      else
        @cp_owner = User.cp_owner.where(channel_partner_id: @channel_partner.id).first
        @channel_partner = ChannelPartner.new(permitted_attributes([:admin, ChannelPartner.new]))
        respond_to do |format|
          err_msg = t('controller.channel_partners.create.not_allowed_message', owner_name: @cp_owner&._name || 'Admin')
          flash.now[:alert] = err_msg
          format.html { render :new, status: :unprocessable_entity}
          format.json { render json: { errors: err_msg }, status: :unprocessable_entity }
        end
      end
    end
  end

  def update
    authorize([:admin, @channel_partner])
    @channel_partner.assign_attributes(permitted_attributes([:admin, @channel_partner]))
    respond_to do |format|
      if (params.dig(:channel_partner, :event).present? ? @channel_partner.send("#{params.dig(:channel_partner, :event)}!") : @channel_partner.save)
        format.html { redirect_to (request.referer || channel_partners_path), notice: 'Channel Partner was successfully updated.' }
        format.json { render json: @channel_partner }
      else
        format.html { render :edit }
        format.json { render json: { errors: @channel_partner.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def change_state
    respond_to do |format|
      if params.dig(:channel_partner, :event).present? && @channel_partner.send("#{params.dig(:channel_partner, :event)}!")
        format.html { redirect_to request.referer, notice: t("controller.channel_partners.status_message.#{@channel_partner.status}") }
        format.json { render json: @channel_partner }
      else
        format.html { redirect_to request.referer, alert: (@channel_partner.errors.full_messages.uniq.presence || 'Something went wrong') }
        format.json { render json: { errors: (@channel_partner.errors.full_messages.uniq.presence || 'Something went wrong') }, status: :unprocessable_entity }
      end
    end
  end

  def asset_form
    respond_to do |format|
      format.js
    end
  end

  private

  def set_channel_partner
    @channel_partner = ChannelPartner.find(params[:id])
  end

  def authorize_resource
    unless params[:action] == 'index' && params[:ds] == 'true'
      if params[:action] == 'index' || params[:action] == 'export'
        authorize [:admin, ChannelPartner]
      elsif ["new","new_channel_partner"].include?params[:action]
        authorize [:admin, ChannelPartner.new]
      elsif ["create","create_channel_partner"].include?params[:action]
        authorize [:admin, ChannelPartner.new(permitted_attributes([:admin, ChannelPartner.new]))]
      else
        authorize [:admin, @channel_partner]
      end
    end
  end

  def apply_policy_scope
    custom_scope = ChannelPartner.where(ChannelPartner.user_based_scope(current_user, params))
    ChannelPartner.with_scope(policy_scope(custom_scope)) do
      yield
    end
  end
end
