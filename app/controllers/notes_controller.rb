class NotesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_notable
  before_action :authorize_resource
  around_action :apply_policy_scope, only: :index

  def new
    @note = Note.new(notable: @notable)
    render layout: false
  end

  def create
    @note = Note.new(notable: @notable, creator: current_user)
    @note.assign_attributes(permitted_attributes([current_user_role_group, Note.new]))
    authorize [current_user_role_group, @note]
    respond_to do |format|
      if @note.save
        format.json { render json: @note, status: :created }
      else
        format.json { render json: {errors: @note.errors.full_messages.uniq}, status: :unprocessable_entity }
      end
    end
  end

  private
  def set_notable
    @notable = params[:notable_type].classify.constantize.find params[:notable_id]
  end

  def authorize_resource
    authorize [current_user_role_group, @notable], :show?
    if params[:action] == "index"
    elsif params[:action] == "new" || params[:action] == "create"
      authorize [current_user_role_group, Note.new(notable: @notable)]
    else
      authorize [current_user_role_group, @note]
    end
  end

  def apply_policy_scope
    Note.with_scope(policy_scope(Note.all)) do
      yield
    end
  end
end
