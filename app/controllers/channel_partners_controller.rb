class ChannelPartnersController < ApplicationController
  before_action :authenticate_user!, except: [:new, :create]
  before_action :set_channel_partner, only: [:show, :edit, :update, :destroy]
  around_action :apply_policy_scope
  before_action :authorize_resource

  layout :set_layout

  def index
    @channel_partners = ChannelPartner.all
  end

  def show
  end

  def new
    @channel_partner = ChannelPartner.new
  end

  def edit
  end

  def create
    @channel_partner = ChannelPartner.new(permitted_attributes(ChannelPartner.new))

    respond_to do |format|
      if @channel_partner.save
        format.html { redirect_to (user_signed_in? ? channel_partners_path : root_path), notice: 'Channel partner was successfully created.' }
      else
        format.html { render :new }
      end
    end
  end

  def update
    respond_to do |format|
      if @channel_partner.update(permitted_attributes(@channel_partner))
        format.html { redirect_to channel_partners_path, notice: 'Channel partner was successfully updated.' }
      else
        format.html { render :edit }
      end
    end
  end

  private
  def set_channel_partner
    @channel_partner = ChannelPartner.find(params[:id])
  end

  def authorize_resource
    if params[:action] == "index"
      authorize ChannelPartner
    elsif params[:action] == "new"
      authorize ChannelPartner.new
    elsif params[:action] == "create"
      authorize ChannelPartner.new(permitted_attributes(ChannelPartner.new))
    else
      authorize @channel_partner
    end
  end

  def apply_policy_scope
    custom_scope = ChannelPartner.all.criteria
    ChannelPartner.with_scope(policy_scope(custom_scope)) do
      yield
    end
  end
end
