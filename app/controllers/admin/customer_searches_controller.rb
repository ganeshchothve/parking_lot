class Admin::CustomerSearchesController < AdminController

  include CustomerSearchConcern
  before_action :set_customer_search, only: %w[show update]
  before_action :authorize_resource
  before_action :check_cp_user_presence, only: %w[update], if: :search_step_is_customer?


  def new
    @customer_search = CustomerSearch.new
  end

  def create
    @customer_search = CustomerSearch.new(booking_portal_client: current_user.booking_portal_client)
    search_for_customer
    respond_to do |format|
      if (params[:new] == 'true' && @customer_search.save) || @customer_search.save(context: :customer)
        if params[:new] == 'true' || @customer_search.valid?(:customer)
          format.html { redirect_to admin_customer_search_path(@customer_search) }
        else
          format.html { redirect_to admin_customer_search_path(@customer_search), alert: @customer_search.errors.full_messages }
        end
        format.json { render json: {model: @customer_search, location: admin_customer_search_path(@customer_search)} }
      else
        flash.now[:alert] = @customer_search.errors.full_messages
        format.html { render :new }
        format.json { render json: {errors: @customer_search.errors.full_messages} }
      end
    end
  end

  def show
    set_user_kyc if @customer_search.step == 'kyc'
  end

  def update
    respond_to do |format|
      customer = @customer_search.customer

      if customer.customer_status.to_s.in?(%w(queued av_done engaged))

        format.html { redirect_to admin_customer_search_path(@customer_search), alert: "Customer is already in #{customer.customer_status} state" }
        format.json { render json: {errors: "Customer is already in #{customer.customer_status} state"}, status: :unprocessable_entity }
      else
        update_step

        if @errors.blank?

          if @customer_search.save(context: @customer_search.step.to_sym)

            if @customer_search.step == 'queued'

              if customer.is_revisit?
                queue_number_notice = "Re-Visit Queue number for #{customer.try(:name)} is #{customer.queue_number}"
              else
                queue_number_notice = "Queue number for #{customer.try(:name)} is #{customer.queue_number}"
              end

              send_notification

              format.html { redirect_to new_admin_customer_search_path(queue_number_notice: queue_number_notice) }
              format.json { render json: {model: @customer_search, location: admin_customer_search_path(@customer_search)} }

            elsif @customer_search.step == 'not_queued'
              format.html { redirect_to new_admin_customer_search_path(queue_number_notice: I18n.t("controller.customer_searches.notice.cannot_be_queued", name: customer.try(:name))) }
              format.json { render json: {model: @customer_search, location: admin_customer_search_path(@customer_search)} }

            else
              format.html { redirect_to admin_customer_search_path(@customer_search) }
              format.json { render json: {model: @customer_search, location: admin_customer_search_path(@customer_search)} }
            end

          else
            format.html { redirect_to admin_customer_search_path(@customer_search), alert: @customer_search.errors.full_messages }
            format.json { render json: {errors: @customer_search.errors.full_messages} }
          end

        else
          format.html { redirect_to admin_customer_search_path(@customer_search), alert: @errors }
          format.json { render json: {errors: @errors} }
        end
      end
    end
  end

  private

  def send_notification
    lead = @customer_search.customer
    if lead
      template = ::Template::SmsTemplate.where(booking_portal_client_id: current_client.try(:id)).where(name: "queue_number_notice", project_id: lead.project_id).first
      sms = Sms.create!(
        booking_portal_client_id: lead.user.booking_portal_client_id,
        to: [lead.phone],
        sms_template_id: template.id,
        triggered_by_id: lead.id,
        triggered_by_type: lead.class.to_s
      ) if template
    end
  end

  def set_user_kyc
    if @customer_search.user_kyc
      @user_kyc = @customer_search.user_kyc
    else
      _customer = @customer_search.customer
      @user_kyc = _customer.user_kycs.where(booking_portal_client_id: current_client.try(:id)).where(default: true).first
      if !@user_kyc.present?
        @user_kyc = _customer.user_kycs.build(creator: current_user, first_name: _customer.first_name, last_name: _customer.last_name, email: _customer.email, phone: _customer.phone, default: true)
      end
    end
  end

  def set_customer_search
    @customer_search = CustomerSearch.where(booking_portal_client_id: current_client.try(:id)).where(id: params[:id]).first
    redirect_to root_path, alert: t('controller.customer_searches.set_customer_search_missing'), status: 404 if @customer_search.blank?
  end

  def check_cp_user_presence
    if params[:manager_id].present?
      cp_user = User.where(booking_portal_client_id: current_client.try(:id)).where(id: params[:manager_id]).first
      render json: {errors: I18n.t("controller.channel_partners.alert.not_found")}, status: :not_found and return unless cp_user.present?
    end
  end

  def search_step_is_customer?
    @customer_search.step == "customer" if @customer_search.present?
  end

end
