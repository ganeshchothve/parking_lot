class Admin::ClientsController < AdminController
  before_action :set_client
  before_action :authorize_resource
  layout :set_layout

  def edit
    render layout: false
  end

  def show
  end

  def update
    @client.assign_attributes(permitted_attributes([:admin, @client]))
    respond_to do |format|
      if @client.save
        format.html { redirect_to admin_clients_path, notice: 'Client successfully updated.' }
        format.json { render json: @client }
      else
        format.html { render :edit }
        format.json { render json: {errors: @client.errors.full_messages}, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_client
    @client = current_client
  end

  def authorize_resource
    authorize [:admin, @client]
  end
end
