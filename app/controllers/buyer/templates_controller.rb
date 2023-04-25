class Buyer::TemplatesController < BuyerController
  before_action :authorize_resource
  before_action :set_subject_class, only: [:choose_template_for_print, :print_template]

  layout :set_layout

  def choose_template_for_print
    render layout: false
  end

  def print_template
    respond_to do |format|
      @template = Template::CustomTemplate.where(id: params[:template_id], booking_portal_client_id: current_client.try(:id)).first
      if @template.present?
        format.html { render template: 'admin/templates/print_template' }
      else
        format.html { redirect_to request.referer, alert: "Template not found" }
      end
    end
  end

  private

  def set_subject_class
    @subject_class = params[:subject_class].classify.constantize.to_s
    @subject_class_resource = params[:subject_class].classify.constantize.find params[:subject_class_id]
  end

  def authorize_resource
    if %w(choose_template_for_print print_template).include?(params[:action])
      authorize [:buyer, ::Template] 
    else
      authorize [:buyer, @template]
    end
  end
end
