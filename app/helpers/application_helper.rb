module ApplicationHelper
  def global_labels
    I18n.t('global').with_indifferent_access
  end

  def global_label(key, params={})
    I18n.t("global.#{key}", params)
  end

  def number_to_indian_currency(number, currency = nil)
    if number
      negative = number < 0
      string = number.abs.to_s.split('.')
      number = string[0].to_s.gsub(/(\d+)(\d{3})$/){ p = $2;"#{$1.reverse.gsub(/(\d{2})/,'\1,').reverse},#{p}"}
      number = number.gsub(/^,/, '')
      number = number + '.' + string[1] if string[1].to_f > 0
    end
    currency ||= 'default'
    "#{negative ? '- ' : ''}#{I18n.t('currency.' + currency.to_s)}#{number}".html_safe
  end

  def number_to_inr(number, options={})
    CurrencyConverter.convert(number, options.merge(units: :inr))
  end

  def get_view_erb(template, options={})
    unless options[:check_active] && !template.is_active?
      begin
        ::ERB.new(template.content).result( options[:binding] || binding ).html_safe
      rescue StandardError => e
        ERB.new("<script> Amura.global_error_handler(''); </script>").result(binding).html_safe
      end
    end
  end

  def login_image
    # client_asset_image_url('login_page_image') ? ('background-image: url(' + client_asset_image_url('login_page_image') + ')') : ''
  end

  def client_asset_image_url(document_type = nil)
    if document_type
      image = current_client.assets.where(document_type: document_type).first
      if image
        image.file.try(:url)
      end
    end
  end

  def project_asset_image_url(project, document_type = nil)
    if project && document_type
      image = project.assets.where(document_type: document_type).first
      if image
        image.file.try(:url)
      end
    end
  end

  def float_to_int (x)
    Float(x)
    i, f = x.to_i, x.to_f
    i == f ? i : f
  rescue ArgumentError
    x
  end

  def calculate_percent(amount, percent)
    amount = amount * percent/100
    amount.round
  end

  def get_client_from_domain
    if defined?(request) && request && request.domain.present?
      domain = (request.subdomain.present? ? "#{request.subdomain}." : "") + "#{request.domain}"
      client = Client.in(booking_portal_domains: domain).first
    end
    client
  end

  def current_client
    return @current_client if @current_client.present?
    @current_client = if current_project.present?
                        @current_project.booking_portal_client
                      elsif current_domain
                        Client.in(booking_portal_domains: current_domain).first
                      end
    if @current_client.blank? && defined?(current_user) && current_user.present?
      @current_client = if current_user.role?('superadmin')
                          (Client.where(id: current_user.selected_client_id).first || current_user.booking_portal_client)
                        else
                          current_user.booking_portal_client
                        end
    end
    @current_client
  end

  def current_project
    return @current_project if @current_project.present?
    # TODO: for now we are considering one project per client only so loading first client project here
    if current_domain
      @current_project = Project.in(booking_portal_domains: current_domain).first
    end
    @current_project
  end

  def current_domain
    if defined?(request) && request && request.subdomain.present? && request.domain.present?
      (request.subdomain.present? ? "#{request.subdomain}." : "") + "#{request.domain}"
    end
  end

  def current_lead
    @current_lead ||= Lead.where(booking_portal_client_id: current_client.try(:id), user_id: current_user.id, project_id: current_project.id).first if (defined?(current_user) && current_user.buyer? && current_project.present?)
    @current_lead
  end

  def marketplace?
    valid = current_client.try(:kylas_tenant_id).present?
    unless valid
      valid = request.host == ENV_CONFIG[:marketplace_host].to_s
    end
    valid
  end

  def marketplace_layout?
    request.host == ENV_CONFIG[:marketplace_host].to_s
  end

  # Kylas i-Frame URL
  def embedded_marketplace?
    request.host == ENV_CONFIG[:embedded_marketplace_host].to_s
  end

  def available_templates(subject_class, subject_class_resource)
    project_id = (subject_class == 'Project' ? subject_class_resource.id : subject_class_resource.try(:project_id))
    custom_templates = ::Template::CustomTemplate.where(subject_class: subject_class, booking_portal_client_id: subject_class_resource.booking_portal_client_id, is_active: true).in(project_ids: [project_id, []]).pluck(:name, :id)
    custom_templates
  end

  def bottom_navigation(classes='')
    html = ''
    #if current_user && current_client.brochure.present? && current_client.brochure.url.present?
    #  html += "<li >
    #  #{active_link_to 'Brochure', download_brochure_path, active: :exclusive, class: 'footer-link' }
    #  </li>"
    #end
    #if current_user
    #  html += "<li >
    #  #{active_link_to 'Docs', dashboard_documents_path, active: :exclusive, class: 'footer-link'}
    #  </li>"
    #end
    if current_client.present? && policy([current_user_role_group, current_client]).allow_marketplace_access?
      if current_client.gallery.present? && current_client.gallery.assets.select{|x| x.persisted?}.present?
        html += "<li >
          #{active_link_to 'Gallery', dashboard_gallery_path, active: :exclusive, class: 'footer-link'}
        </li>"
      end
      if current_client.faqs.present?
        html += "<li >
          #{active_link_to 'FAQs', dashboard_faqs_path, active: :exclusive, class: 'footer-link'}
        </li>"
      end
      if current_client.rera.present?
        html += "<li >
          #{active_link_to 'RERA', dashboard_rera_path, active: :exclusive, class: 'footer-link'}
        </li>"
      end
      if current_client.tds_process.present?
        html += "<li >
          #{active_link_to 'TDS', dashboard_tds_process_path, active: :exclusive, class: 'footer-link'}
        </li>"
      end
      #if current_client.terms_and_conditions.present?
      #  html += "<li >
      #    #{active_link_to 'T & C', dashboard_terms_and_condition_path, active: :exclusive, class: 'footer-link'}
      #  </li>"
      #end
      if current_user && policy([current_user_role_group, current_client]).edit?
        html += "<li >
          #{link_to( t('controller.clients.edit.link_name'), edit_admin_client_path, class: 'footer-link modal-remote-form-link')}
        </li>"
      end
      if current_user && current_client.gallery.present? && policy([current_user_role_group, Asset.new(assetable: current_client.gallery)]).index? && current_user.role?("superadmin")
        html += "<li >
          #{link_to( t('controller.assets.new.link_name'), assetables_path(assetable_type: current_client.gallery.class.model_name.i18n_key.to_s, assetable_id: current_client.gallery.id), class: 'footer-link modal-remote-form-link')}
        </li>"
      end
      if current_user && TemplatePolicy.new(current_user, Template).index?
        html += "<li >
          #{link_to(t('helpers.show.link_name', model: ::Template.model_name.human), admin_client_templates_path, class: 'footer-link')}
        </li>"
      end
      if current_user && policy([current_user_role_group, Asset.new(assetable: current_client)]).index? && current_user.role?("superadmin")
        html += "<li >
          #{link_to( t('controller.assets.index.link_name'), assetables_path(assetable_type: current_client.class.model_name.i18n_key.to_s, assetable_id: current_client.id), class: 'footer-link modal-remote-form-link')}
        </li>"
      end
      if current_user && policy([current_user_role_group, PublicAsset.new(public_assetable: current_client)]).index? && current_user.role?("superadmin")
        html += "<li >
          #{link_to( t('controller.public_assets.index.link_name'), public_assetables_path(public_assetable_type: current_client.class.model_name.i18n_key.to_s, public_assetable_id: current_client.id), class: 'footer-link modal-remote-form-link')}
        </li>"
      end
      if current_user.buyer? && current_client.support_number.present?
        html += "<li class = 'footer-object'>
        #{I18n.t("helpers.need_help", name: current_client.support_number)}
        </li>"
      end
      if current_user.channel_partner? && current_client.channel_partner_support_number.present?
        html += "<li  class = 'footer-object'>
        #{I18n.t("helpers.need_help", name: current_client.channel_partner_support_number)}
        </li>"
      end
    end
    html.html_safe
  end

  def current_user_role_group
    current_user.buyer? ? :buyer : :admin
  end

  def flash_class(level)
    case level
      when 'notice' then "alert alert-info"
      when 'success' then "alert alert-success"
      when 'error' then "alert alert-danger"
      when 'alert' then "alert alert-warning"
    end
  end

  #def link_to_if(condition, name, options = {}, html_options = {}, &block)
  #  if condition
  #    link_to(name, options, html_options, &block)
  #  else
  #    if block_given?
  #      block.arity <= 1 ? capture(name, &block) : capture(name, options, html_options, &block)
  #    else
  #      ERB::Util.html_escape(name)
  #    end
  #  end
  #end

  def system_srd
    if user_signed_in? && current_user.role?('channel_partner')
      current_client.selldo_cp_srd
    else
      current_client.selldo_default_srd
    end
  end

  def short_url destination_url, set_expired_at = false, current_client_id = nil
    client = Client.where(id: current_client_id).first
    uri = ShortenedUrl.clean_url(destination_url)
    if shortened_url = ShortenedUrl.where(original_url: uri.to_s).first
      uri.path = "/s/" + shortened_url.code
    else
      shortened_url = ShortenedUrl.create(original_url: uri.to_s)
      uri.path = "/s/" + shortened_url.code
    end
    shortened_url.set(expired_at: (DateTime.current + client.payment_link_validity_hours.hours)) if (client.present? && set_expired_at)
    uri.query = nil
    uri.fragment = nil
    uri.to_s
  end

  def device_type
    client = DeviceDetector.new(request.env['HTTP_USER_AGENT'])
    client.device_type
  end

  def device_type?(type)
    case type
    when 'mobile'
      device_type.in?(['smartphone', 'feature phone', 'phablet', 'tablet'])
    when 'desktop'
      device_type.in?(%w(desktop tv))
    end
  end

  def full_page_view?
    action_name.in?(%w(generate_booking_detail_form generate_invoice sales_board quotation channel_partners_leaderboard_without_layout dashboard_landing_page payout_dashboard payout_list payout_show print_template reset_password_after_first_login select_client))
  end

  def select_icon(content_type = nil)
    case content_type
    when "application/pdf"
      "pdf"
    when "application/doc"
      "docs"
    when /^excel/
      "excel"
    when /^ppt/
      "ppt"
    when "application/zip", "application/x-zip-compressed"
      "zip"
    else
      "pdf"
    end
  end

  def is_marketplace?
    marketplace?
  end

  def marketplace_layout
    'mp/application'
  end

  def application_layout
    'application'
  end

  def devise_layout
    'devise'
  end

  def create_avatar_name
    return if current_user.blank?

    current_user.name ? current_user.name[0].upcase! : current_user.email[0].upcase!
  end

  def active_class(cont_name)
    controller_name == cont_name ? 'active' : ''
  end

  def current_translations
    @translations ||= I18n.backend.send(:translations)
    @translations[I18n.locale].with_indifferent_access
  end
end
