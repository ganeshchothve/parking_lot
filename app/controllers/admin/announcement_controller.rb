class Admin::AnnouncementController < ApplicationController
  include AnnouncementsConcern

  before_action :authenticate_user!
  before_action :set_announcement, only: %i[show edit update]
  before_action :authorize_resource
  # around_action :apply_policy_scope, only: %i[index]

  # layout :set_layout

  # def edit
  #   render layout: false
  # end

  # def new
  #   @announcement = Announcement.new
  #   render layout: false
  # end

  # def create
  #   @announcement = Announcement.new
  #   @announcement.assign_attributes(permitted_attributes([current_user_role_group, @announcement]))
  #   @announcement.creator = current_user
    
  #   respond_to do |format|
  #     if @announcement.save
  #       format.html { redirect_to admin_announcement_index_path, notice: 'Announcement was successfully created.' }
  #       format.json { render json: @announcement, status: :created }
  #     else
  #       format.html { render :new }
  #       format.json { render json: { errors: @announcement.errors.full_messages.uniq }, status: :unprocessable_entity }
  #     end
  #   end
  # end
end
