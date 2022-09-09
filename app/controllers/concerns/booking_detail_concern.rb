module BookingDetailConcern
  extend ActiveSupport::Concern

  def generate_booking_detail_form
    render template: "admin/booking_details/generate_booking_detail_form"
  end

  def choose_template_for_print
    render layout: false
  end

  def print_template
    respond_to do |format|
      @template = Template.where(id: params.dig(:booking_detail, :template_docs), project_id: @booking_detail.project_id, booking_portal_client_id: @booking_detail.booking_portal_client_id).first
      if @template.present?
        format.html { render template: 'admin/booking_details/print_template' }
      else
        format.html { redirect_to admin_booking_details_path, alert: "Template not found" }
      end
    end
  end

  def apply_policy_scope
    custom_scope = BookingDetail.where(BookingDetail.user_based_scope(current_user, params))
    BookingDetail.with_scope(policy_scope(custom_scope)) do
      yield
    end
  end
end
