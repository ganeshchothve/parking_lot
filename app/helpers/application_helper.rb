module ApplicationHelper
  def global_labels
    t('global').with_indifferent_access
  end

  def global_label(key, params={})
    t("global.#{key}", params)
  end

  def number_to_indian_currency(number)
    if number
      string = number.to_s.split('.')
      number = string[0].gsub(/(\d+)(\d{3})$/){ p = $2;"#{$1.reverse.gsub(/(\d{2})/,'\1,').reverse},#{p}"}
      number = number.gsub(/^,/, '')
      number = number + '.' + string[1] if string[1].to_f > 0
    end
    "&#8377;#{number}".html_safe
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

  def current_client
    return @current_client if @current_client.present?
    if defined?(request) && request && request.subdomain.present? && request.domain.present?
      domain = (request.subdomain.present? ? "#{request.subdomain}." : "") + "#{request.domain}"
      @current_client = Client.in(booking_portal_domains: domain).first
    else
      @current_client = Client.asc(:created_at).first # GENERICTODO: handle this
    end
  end

  def current_project
    return @current_project if @current_project.present?
    # TODO: for now we are considering one project per client only so loading first client project here
    @current_project = current_client.projects.first if current_client.present?
  end

  def bottom_navigation(classes='')
    html = ''
    if current_user
      html += "<li class='nav-item #{classes}'>
      #{active_link_to 'Docs', dashboard_documents_path, active: :exclusive, class: 'small nav-link'}
      </li>"
    end
    if current_client.gallery.present? && current_client.gallery.assets.select{|x| x.persisted?}.present?
      html += "<li class='nav-item #{classes}'>
        #{active_link_to 'Gallery', dashboard_gallery_path, active: :exclusive, class: 'small nav-link'}
      </li>"
    end
    if current_client.faqs.present?
      html += "<li class='nav-item #{classes}'>
        #{active_link_to 'FAQs', dashboard_faqs_path, active: :exclusive, class: 'small nav-link'}
      </li>"
    end
    if current_client.rera.present?
      html += "<li class='nav-item #{classes}'>
        #{active_link_to 'RERA', dashboard_rera_path, active: :exclusive, class: 'small nav-link'}
      </li>"
    end
    if current_client.tds_process.present?
      html += "<li class='nav-item #{classes}'>
        #{active_link_to 'TDS', dashboard_tds_process_path, active: :exclusive, class: 'small nav-link'}
      </li>"
    end
    if current_client.terms_and_conditions.present?
      html += "<li class='nav-item #{classes}'>
        #{active_link_to 'T & C', dashboard_terms_and_condition_path, active: :exclusive, class: 'small nav-link'}
      </li>"
    end
    if current_user && policy([current_user_role_group, current_client]).edit?
      html += "<li class='nav-item #{classes}'>
        #{link_to('Edit ' + global_labels['client'], edit_admin_client_path, class: 'small nav-link modal-remote-form-link')}
      </li>"
    end
    if current_user && current_client.gallery.present? && policy([current_user_role_group, Asset.new(assetable: current_client.gallery)]).index? && current_user.role?("superadmin")
      html += "<li class='nav-item #{classes}'>
        #{link_to('Edit ' + global_labels[:gallery], assetables_path(assetable_type: current_client.gallery.class.model_name.i18n_key.to_s, assetable_id: current_client.gallery.id), class: 'small nav-link modal-remote-form-link')}
      </li>"
    end
    if current_user && TemplatePolicy.new(current_user, Template).index?
      html += "<li class='nav-item #{classes}'>
        #{link_to('Manage ' + global_labels['templates'], admin_client_templates_path, class: 'small nav-link')}
      </li>"
    end
    if current_user && policy([current_user_role_group, Asset.new(assetable: current_client)]).index? && current_user.role?("superadmin")
      html += "<li class='nav-item #{classes}'>
        #{link_to('Client ' + global_labels[:assets], assetables_path(assetable_type: current_client.class.model_name.i18n_key.to_s, assetable_id: current_client.id), class: 'small nav-link modal-remote-form-link')}
      </li>"
    end
    html.html_safe
  end

  def current_user_role_group
    current_user.buyer? ? :buyer : :admin
  end
end
