class NotesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_notable
  before_action :set_note, only: :destroy
  before_action :authorize_resource
  around_action :apply_policy_scope, only: :index

  def index
    @notes = @notable.notes.paginate(page: params[:page] || 1, per_page: params[:per_page])
    respond_to do |format|
      format.js
    end
  end

  def new
    @note = Note.new(notable: @notable, booking_portal_client: current_client)
    render layout: false
  end

  def create
    @note = Note.new(
                  notable: @notable, 
                  creator: current_user,
                  booking_portal_client: current_client)
    @note.assign_attributes(permitted_attributes([current_user_role_group, Note.new]))
    authorize [current_user_role_group, @note]
    respond_to do |format|
      if @note.save
        SelldoNotePushWorker.perform_async(@note.notable.lead_id, current_user.id.to_s, @note.note) if @note.notable.class.to_s == 'Lead' && current_user.role?(:channel_partner)
        if is_marketplace?
          response = Kylas::CreateNote.new(current_user, @note).call
          response = response.with_indifferent_access
          @note.set(kylas_note_id: response.dig(:data, :id))
        end
        format.json { render json: @note, status: :created }
      else
        format.json { render json: {errors: @note.errors.full_messages.uniq}, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    respond_to do |format|
      if @note.destroy
        Kylas::DeleteNote.new(current_user, @note).call if is_marketplace?
        format.html { redirect_to admin_leads_path, notice: 'Note was successfully destroyed' }
        format.json {render json: {}, status: :ok}
      else
        format.html { redirect_to admin_leads_path, notice: 'Unable to delete note' }
        format.json {render json: {errors: @note.errors.full_messages.to_sentence}, status: :unprocessable_entity}
      end
    end
  end

  private
  def set_notable
    @notable = params[:notable_type].classify.constantize.find params[:notable_id]
  end

  def set_note
    @note = Note.where(id: params[:id]).first if params[:id].present?
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
