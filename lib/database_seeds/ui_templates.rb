# frozen_string_literal: true

# DatabaseSeeds::UITemplate.seed CLient.last.id
module DatabaseSeeds
  module UITemplate
    def self.client_based_seed(client_id)
      # To add links for videos
      if Template::UITemplate.where(name: 'assets/_videos', booking_portal_client_id: client_id).blank?
        Template::UITemplate.create({ booking_portal_client_id: client_id, subject_class: 'View', name: 'assets/_videos', content: '<div class="row">
          <div class="col-12 my-4 text-center">
          </div>
        </div>' })
      end

      # To render card on user dashboard
      if Template::UITemplate.where(name: 'users/_welcome', booking_portal_client_id: client_id).blank?
        Template::UITemplate.create({ booking_portal_client_id: client_id, subject_class: 'View', name: 'users/_welcome', content: '
        <div class="col-lg-12 col-md-12 col-sm-12 col-xs-12 bg-primary">
          <div class="box-content">
            <h1 class="wc-title white text-center">Welcome <%= current_user.name %></h1>
            <% if current_user.receipts.present? && !current_client.enable_actual_inventory?(current_user) %>
              <p class="white text-center fn-300 fn-18">Congratulations on generating your Priority Token for allotment day. Make additional payment to get more tokens</p>
            <% else %>
              <p class="white text-center fn-300 fn-18">Now get privileged access to <%= current_project.project_size %> spread township and book your dream home by just paying <%= number_to_indian_currency(current_client.blocking_amount) %><br>400+ customers have already paid a token amount and now it\'s your chance to roll the dice by following below steps</p>
            <% end %>
            <ul class="step-booking">
              <li>
                <span><%= image_tag "file-invoice.svg", alt: "Invoice" %></span>
                <%= link_to "Fill KYC Form", [:new, current_user_role_group, :user_kyc], class: "modal-remote-form-link" %>
              </li>
              <li>
                <span><%= image_tag "rupee-blue.svg", alt: "Rupee" %></span>
                <%= link_to_if !current_user.user_kyc_ids.blank?, "Pay Remaining Amount",[:new, current_user_role_group, :receipt ], { class: "modal-remote-form-link"} %>
              </li>
              <li>
                <span><%= image_tag "get-token.svg", alt: "Building", style: "width:40px;" %></span>
                <%= link_to_if policy([current_user_role_group, ProjectUnit.new(user: current_user, status: "available")]).hold?, "Get Priority Token", new_search_path %>
              </li>
            </ul>

            <div class = "row">
              <div class = "col text-center">
                <% if current_user.kyc_ready? && current_user.booking_details.in(status: BookingDetail::BOOKING_STAGES).count >= current_user.allowed_bookings %>
                    <p class="white text-center fn-14 fn-500">You cannot book any more apartments as you have reached the maximum bookings allowed per customer.</p>
                <% elsif current_user.kyc_ready? && current_client.enable_actual_inventory?(current_user) %>
                  <%= booking_detail = current_user.booking_details.hold.first %>
                  <% if booking_detail && booking_detail.search %>
                    <!-- <p class="white text-center fn-14 fn-500">You already have a unit on hold.</p> -->
                    <%= link_to "Checkout using unit already held", checkout_user_search_path(booking_detail.search), class: "large-btn black-bg display-block fn-500 center-block show-kyc width-250 btn btn-white border rounded white" %>
                  <% else %>
                    <% if policy([current_user_role_group, ProjectUnit.new(user: current_user, status: "available")]).hold? %>
                      <!-- <p class="white text-center fn-14 fn-500">Choose Apartment</p> -->
                      <%= link_to t("controller.buyer.dashboard.book_apartment"), new_search_path, class: "large-btn black-bg display-block fn-500 center-block show-kyc btn btn-white border rounded white" %>
                    <% end %>
                  <% end %>
                <% elsif current_user.kyc_ready? %>
                  <!-- <p class="white text-center fn-14 fn-500">Make Payment to proceed further</p> -->
                  <%= link_to t("controller.buyer.dashboard.add_payment"), new_buyer_receipt_path, class: "large-btn black-bg display-block fn-500 center-block show-kyc modal-remote-form-link btn btn-white border rounded white" %>
                <% else %>
                  <!-- <p class="white text-center fn-14 fn-500">Fill your KYC form to proceed further</p> -->
                  <%= link_to t("controller.buyer.dashboard.fill_kyc_form"), new_buyer_user_kyc_path, class: "large-btn black-bg display-block fn-500 center-block show-kyc modal-remote-form-link btn btn-white border rounded white" %>
                <% end%>
              </div>
            </div>
          </div>
        </div>' })
      end

      # To render projects section card on user dashboard
      if Template::UITemplate.where(name: 'project_units/_section', booking_portal_client_id: client_id).blank?
        Template::UITemplate.create({ booking_portal_client_id: client_id, subject_class: 'View', name: 'project_units/_section', content: <<-'INACTIVE_CP'
        <div class="col-lg-12 col-xs-12 col-md-12 col-sm-12 my-4 no-pd">
          <div class="box-card">
            <div class="box-header bg-primary br-rd-tr-4">
              <h2 class="title icon-set icon-building-white">
                <%= Project.model_name.human %>
              </h2>
            </div>
            <div class="project-slider1">
              <div>
                <div class="box-content br-rd-bl-4 bg-white text-center">
                  <h3 class="title"><%= current_user.selected_project.name %></h3>
                  <p class="sort-desc col-lg-6 col-xs-12 col-md-6 col-sm-12 offset-md-3 offset-lg-3"><%= t("dashboard.user.projects.sub_heading") %></p>
                  <ul class="prjt-info br-rd-4">
                    <li><span><%= t("dashboard.user.titles.available_inventory") %></span><p><%= DashboardDataProvider.available_inventory(current_user, current_user.selected_project) %></p></li>
                    <li><span><%= t("mongoid.attributes.search.starting_price") %></span><p><%= number_to_indian_currency(DashboardDataProvider.minimum_agreement_price(current_user, current_user.selected_project)) %></p></li>
                    <li><span><%= t("mongoid.attributes.project_unit.configuration") %></span><p><%= DashboardDataProvider.configurations(current_user, current_user.selected_project).to_sentence(last_word_connector: " & ") %></p></li>
                  </ul>
                  <% brochure = current_user.selected_project.assets.where(document_type: 'brochure').first %>
                  <% if brochure.present? %>
                    <ul class="prjt-link">
                      <li><%= link_to t("dashboard.user.titles.download_brochure"), brochure.file.url, target: "_blank", class: "text-uppercase" %></li>
                    </ul>
                  <% end %>
                  <%= link_to "Visit Website >", current_user.selected_project.website_link, target: "_blank", class: "large-btn bg-light-blue display-block fn-500 center-block text-uppercase" %>
                </div>
              </div>
            </div>
          </div>
        </div>
         INACTIVE_CP
        })
      end

      if Template::UITemplate.where(name: 'index/inactive_channel_partner', booking_portal_client_id: client_id).blank?
        Template::UITemplate.create({ booking_portal_client_id: client_id, subject_class: 'View', name: 'index/inactive_channel_partner', content: <<-'INACTIVE_CP'
          <div class="col-lg-12 col-xs-12 bg-primary br-rd-8 col-md-12 col-sm-12">
            <img src="<%= asset_path 'quality-tag.png' %>" alt="user icon" class="quality-tag">
            <div class="row">
              <div class="col-lg-8 col-md-12 col-sm-12 col-xs-12 offset-lg-2">
                <div class="box-content">
                  <h1 class="wc-title white text-center">Welcome <%= current_user.name %></h1>
                  <p class="white text-center fn-300 fn-18">Follow these quick steps and get your account approved to start adding leads<br> and earn amazing benefits</p>
                  <ul class="step-booking">
                    <li class="light-blue">
                      <span> <%= image_tag "file-invoice.svg", alt: "Fill Details" %> </span>
                      <%= link_to_if Admin::ChannelPartnerPolicy.new(current_user, channel_partner).edit?, '<span class="light-blue">Fill Details</span>'.html_safe, edit_channel_partner_path(channel_partner), class: 'modal-remote-form-link' %>
                    </li>
                    <li class="light-blue">
                      <span><%= image_tag "file-kycs.svg" %></span>
                      <%= link_to_if policy([ current_user_role_group, Asset.new(assetable: channel_partner)]).index?, '<span class="light-blue">Upload Documents</span>'.html_safe, assetables_path(assetable_type: channel_partner.class.model_name.i18n_key.to_s, assetable_id: channel_partner.id), class: 'modal-remote-form-link' %>
                    </li>
                    <li class="light-blue">
                      <span><%= image_tag "building-lightblue.svg" %></span>
                      <% if policy([current_user_role_group, channel_partner]).editable_field?('event') %>
                        <%= link_to_if policy([current_user_role_group, channel_partner]).change_state?, "<span class='light-blue'>#{channel_partner.rejected? ? 'Re-' : ''}Submit for Approval</span>".html_safe, change_state_channel_partner_path(channel_partner, {channel_partner: {event: 'submit_for_approval'}}), method: :post, class: 'modal-remote-form-link' %>
                      <% elsif channel_partner.pending? %>
                          Sent for Approval
                      <% end %>
                    </li>
                  </ul>
                  <p class="white text-center fn-14 fn-500">
                  <% if channel_partner.inactive? && !channel_partner.may_submit_for_approval? %>
                    Upload following documents to submit your application<br>
                    <%= channel_partner.doc_types.collect {|x| t("mongoid.attributes.channel_partner/file_types.#{x}")}.to_sentence %>
                  <% elsif channel_partner.pending? %>
                    Thank you for choosing us<br>
                    Please wait while our representative reviews your account and approves
                  <% elsif  channel_partner.rejected? %>
                    Your account got rejected for following reason: <%= channel_partner.status_change_reason %><br>
                    Please resolve the concern and resubmit
                  <% end %>
                  </p>
                </div>
              </div>
            </div>
          </div>
          INACTIVE_CP
        })
      end

      if Template::UITemplate.where(name: 'index/_channel_partner', booking_portal_client_id: client_id).blank?
        Template::UITemplate.create({ booking_portal_client_id: client_id, subject_class: 'View', name: 'index/_channel_partner', content: '
        <div class="col-lg-12 col-xs-12 bg-primary br-rd-8 col-md-12 col-sm-12">
          <img src="<%= asset_path \'quality-tag.png\' %>" alt="user icon" class="quality-tag">
          <div class="row">
            <div class="col-lg-8 col-md-12 col-sm-12 col-xs-12 offset-lg-2">
              <div class="box-content">
                <h1 class="wc-title white text-center">Welcome <%= current_user.name %></h1>
                <p class="white text-center fn-300 fn-18">Follow these quick steps and get your customers to be one of the privileged few to own a home at <%= current_project.name %></p>
                <ul class="step-booking">
                  <li class="light-blue">
                    <span>
                      <%= image_tag "file-invoice.svg", alt: "Add customer" %>
                    </span>Add Customers
                  </li>
                  <li class="light-blue">
                    <span><%= image_tag "rupee.svg" %></span>Pay Remaining Amount
                  </li>
                  <li class="light-blue">
                    <span><%= image_tag "building.svg" %></span><%= BookingDetail.model_name.human %>
                  </li>
                </ul>
                <!-- <p class="white text-center fn-14 fn-500">Fill your KYC form for proceed further</p> -->
                <div class="row">
                  <div class="col">
                    <%= link_to "Add Customer", new_admin_lead_path, class: "large-btn black-bg display-block fn-500 center-block show-kyc modal-remote-form-link" %>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>' })
      end

      # To render card on sales & admin dashboard
      if Template::UITemplate.where(name: 'dashboard/index/_admin', booking_portal_client_id: client_id).blank?
        Template::UITemplate.create({ booking_portal_client_id: client_id, subject_class: 'View', name: 'dashboard/index/_admin', content: '
        <div class="col-lg-12 col-md-12 col-sm-12 col-xs-12 bg-primary">
          <div class="box-content">
            <h1 class="wc-title white text-center">Welcome <%= current_user.name %> </h1>
            <p class="white text-center fn-300 fn-18">Welcome to the Online Booking Portal, Please follow the steps below to complete the project walkthrough with your Customer.</p>
            <ul class="step-booking">
              <li>
                <span><%= image_tag "file-invoice.svg", alt: "Invoice" %></span>
                <%= link_to "Digital Presenter", current_client.assets.where(asset_type: "digital_presenter").first.try(:file).try(:url), target: "_blank" %>
              </li>
              <li>
                <span><%= image_tag "file-invoice.svg", alt: "Rupee" %></span>
                <%= link_to "Floor plans", current_client.assets.where(asset_type: "digital_presenter").first.try(:file).try(:url), target: "_blank" %>
              </li>
              <li>
                <span><%= image_tag "file-invoice.svg", alt: "Building", style: "width:40px;" %></span>
                <%= link_to "Project Walkthrough", "https://d1b2b4oevn2eyz.cloudfront.net/embassy/index.html", target: "_blank" %>
              </li>
            </ul>
          </div>
        </div>' })
      end

      # To change text above login page for admin/sales/user
      if Template::UITemplate.where(name: 'devise/sessions/new', booking_portal_client_id: client_id).blank?
        Template::UITemplate.create({ booking_portal_client_id: client_id, subject_class: 'View', name: 'devise/sessions/new', content: '<h1 class="mt-0 fn-24">Welcome to <%= current_project.name %></h1>
          <p class="p-style mt-0">Now is the best time to turn your dream into reality</p>
          <p class="p-style"><strong>Login</strong> to Book an Apartment online</p>' })
      end

      # To change text on register page for user
      if Template::UITemplate.where(name: 'home/register', booking_portal_client_id: client_id).blank?
        Template::UITemplate.create({ booking_portal_client_id: client_id, subject_class: 'View', name: 'home/register', content: '<h1 class="mt-0 fn-20">Biggest real estate opportunity in Pune<br> Introducing exclusive <%= ProjectUnit.distinct(:unit_configuration_name).map {|x| x.match(/\d*.*\d/).to_s}.uniq.sort.first(3).to_sentence(last_word_connector: " & ") %> Bed residences starting from <%= number_to_indian_currency(DashboardDataProvider.minimum_agreement_price(current_user).to_s.match(/(\d+)\d{5}/).try(:captures).try(:first)) %> lakhs</h1>
        <p class="p-style">Home buying can’t get better than this</p>
        <p><strong>Register Now</strong> to Book Online</p>' })
      end

      # To change text on register page for channel_partner
      if Template::UITemplate.where(name: 'channel_partner/new', booking_portal_client_id: client_id).blank?
        Template::UITemplate.create({ booking_portal_client_id: client_id, subject_class: 'View', name: 'channel_partner/new', content: '<h1 class="mt-0 fn-20">We are a big family of 400+ esteemed partners and we are happy to onboard you</h1>
        <p><strong>Register now</strong> & join our network to explore new opportunities</p>' })
      end

      # To change text in the footer
      if Template::UITemplate.where(name: 'layouts/_navbar_footer', booking_portal_client_id: client_id).blank?
        Template::UITemplate.create({ booking_portal_client_id: client_id, subject_class: 'View', name: 'layouts/_navbar_footer', content: '
          <% if current_project.present? && current_project.rera_registration_no %> <p class="m-0 pb-1"><%= current_project.name %> is registered via MahaRERA No.: <%= current_project.rera_registration_no %> & is available on <a href="https://maharera.mahaonline.gov.in" target="_blank">https://maharera.mahaonline.gov.in</a>.</p><% elsif current_client.present? %><p><%= current_client.name %></p><% end %>' })
      end

      # To change text above timer when booking a unit
      if Template::UITemplate.where(name: 'searches/checkout', booking_portal_client_id: client_id).blank?
        Template::UITemplate.create({ booking_portal_client_id: client_id, subject_class: 'View', name: 'searches/checkout', content: '<p class="p-style white"> To be fair to other user interested in this apartments, we have held this unit for some time. Please go through the costs and payments schedule before you make a payment of <%= number_to_indian_currency(@project_unit.blocking_amount || @project_unit.booking_portal_client.blocking_amount) %></p>' })
      end

      # To change text on show booking detail for user & channel_partner
      # @bd is booking_detail
      if Template::UITemplate.where(name: 'booking_details/_details', booking_portal_client_id: client_id).blank?
          Template::UITemplate.create({ booking_portal_client_id: client_id, subject_class: 'View', name: 'booking_details/_details', content: '<ul>
              <li>You need to pay <%= number_to_indian_currency(@bd.project_unit.get_booking_price) %> to confirm the booking</li>
              <% unless @bd.booking_portal_client.try(:cancellation_amount).try(:zero?) %>
                <li>Cancellation charges are <%= number_to_indian_currency(@bd.booking_portal_client.cancellation_amount) %></li>
              <% end %>
              <% if @bd.project_unit.auto_release_on %>
                <li>You have <%= (@bd.project_unit.auto_release_on - Date.today).to_i %> days (before <%= I18n.l(@bd.project_unit.auto_release_on) %>) remaining to confirm this booking. Please make a remaining payment of <%= number_to_indian_currency(@bd.pending_balance.try(:round)) %></li>
              <% end %>
            </ul>' })
      end

      if Template::UITemplate.where(name: 'quotation_pdf', booking_portal_client_id: client_id).blank?
        Template::UITemplate.create({ booking_portal_client_id: client_id, subject_class: 'View', name: 'quotation_pdf',
 content: <<-'QUOTATION_PDF'
            <div class='text-center'>
              <img src='<%= @booking_detail.booking_portal_client.logo.url.try(:gsub, "https", "http") || '' %>' class='mb-3' width=120>
              <h2><%= current_project.name %></h2>
            </div>
            <%= render 'admin/project_units/project_unit_cost_details', locals: { booking_detail: @booking_detail } %>
            <%= @booking_detail.cost_sheet_template.parsed_content(@booking_detail) %>
            <%= @booking_detail.payment_schedule_template.parsed_content(@booking_detail) %>
          QUOTATION_PDF
        })
      end

      if Template::UITemplate.where(name: 'terms_and_conditions', booking_portal_client_id: client_id).blank?
        Template::UITemplate.create({ booking_portal_client_id: client_id, subject_class: 'View', name: 'terms_and_conditions',
 content: <<-'TERMS_AND_CONDITIONS'
<section class="privacy-policy-sec">
	<div class="container">
		<h1>Terms and Conditions</h1>
	</div>
</section>
          TERMS_AND_CONDITIONS
        })
      end

      if Template::UITemplate.where(name: 'privacy_policy', booking_portal_client_id: client_id).blank?
        Template::UITemplate.create({ booking_portal_client_id: client_id, subject_class: 'View', name: 'privacy_policy',
 content: <<-'PRIVACY_POLICY'
<section class="privacy-policy-sec">
	<div class="container">
		<h1>PRIVACY POLICY</h1>
	</div>
</section>
          PRIVACY_POLICY
        })
      end

      if Template::UITemplate.where(name: 'channel_partner_register', booking_portal_client_id: client_id).blank?
        Template::UITemplate.create({ booking_portal_client_id: client_id, subject_class: 'View', name: 'channel_partner_register',
          content: <<-'CP'
            <div class="col-lg-5 px-0 px-sm-2">
              <div class="cp-signup-features px-2">
                <h2 class="pt-2 pb-2"><%= I18n.t("global.link_to.love_our_brand", name: (current_client.present? ? current_client.name : I18n.t("global.brand", client_name: current_client.name))) %></h2>
                <ul class="list-unstyled mt-4 cp-benefit-list cp-benefit-2row">
                  <li>
                    <div class="features-wrap">
                      <span>
                        <img src="<%= asset_path 'cp-ex-feat-01.svg' %>">
                      </span>
                      <p><%= I18n.t("global.link_to.early_access").html_safe %> <br></p>
                    </div>
                  </li>
                  <li>
                    <div class="features-wrap">
                      <span>
                        <img src="<%= asset_path 'cp-ex-feat-06.svg' %>">
                      </span>
                      <p><%= I18n.t("global.link_to.timely_payments").html_safe %></p>
                    </div>
                  </li>
                  <li>
                    <div class="features-wrap">
                      <span>
                        <img src="<%= asset_path 'cp-ex-feat-05.svg' %>">
                      </span>
                      <p><%= I18n.t("global.link_to.marketing_support").html_safe %></p>
                    </div>
                  </li>
                  <li>
                    <div class="features-wrap">
                      <span>
                        <img src="<%= asset_path 'cp-ex-feat-11.svg' %>">
                      </span>
                      <p><%= I18n.t("global.link_to.performance_based").html_safe %></p>
                    </div>
                  </li>
                  <li>
                    <div class="features-wrap">
                      <span>
                        <img src="<%= asset_path 'cp-ex-feat-02.svg' %>">
                      </span>
                      <p><%= I18n.t("global.link_to.extensive_nurturing").html_safe %></p>
                    </div>
                  </li>
                  <li>
                    <div class="features-wrap">
                      <span>
                        <img src="<%= asset_path 'cp-ex-feat-04.svg' %>">
                      </span>
                      <p><%= I18n.t("global.link_to.crm_training").html_safe %></p>
                    </div>
                  </li>
                  <li>
                    <div class="features-wrap">
                      <span>
                        <img src="<%= asset_path 'cp-ex-feat-07.svg' %>">
                      </span>
                      <p><%= I18n.t("global.link_to.fully_automated").html_safe %></p>
                    </div>
                  </li>
                  <li>
                    <div class="features-wrap">
                      <span>
                        <img src="<%= asset_path 'cp-ex-feat-08.svg' %>">
                      </span>
                      <p><%= I18n.t("global.link_to.online_inventory_selection").html_safe %></p>
                    </div>
                  </li>
                  <li>
                    <div class="features-wrap">
                      <span>
                        <img src="<%= asset_path 'cp-ex-feat-09.svg' %>">
                      </span>
                      <p><%= I18n.t("global.link_to.complete_transparency").html_safe %></p>
                    </div>
                  </li>
                  <li>
                    <div class="features-wrap">
                      <span>
                        <img src="<%= asset_path 'cp-ex-feat-10.svg' %>">
                      </span>
                      <p><%= I18n.t("global.link_to.unique_online").html_safe %></p>
                    </div>
                  </li>
                </ul>
              </div>
            </div>
          CP
        })
      end


      if Template::UITemplate.where(name: 'channel_partner_register_dashboard', booking_portal_client_id: client_id).blank?
        Template::UITemplate.create({ booking_portal_client_id: client_id, subject_class: 'View', is_active: true, name: 'channel_partner_register_dashboard',
          content: <<-'CPDashboard'
            <div class="col-lg-12">
              <h2 class="pb-4"><%= I18n.t("global.link_to.love_our_brand", name: I18n.t("global.brand", client_name: current_client.name)) %></h2>
            </div>
            <div class="col-lg-4 app-features-list">
              <span>
                  <img src="<%= asset_path 'cp-ex-feat-01.svg' %>" width="45">
                </span>
                <p><%= I18n.t("global.link_to.early_access").html_safe %> <br></p>
            </div>
            <div class="col-lg-4 app-features-list">
              <span>
                  <img src="<%= asset_path 'cp-ex-feat-06.svg' %>" width="45">
                </span>
                <p><%= I18n.t("global.link_to.timely_payments").html_safe %></p>
            </div>
            <div class="col-lg-4 app-features-list">
              <span>
                  <img src="<%= asset_path 'cp-ex-feat-05.svg' %>" width="45">
                </span>
                <p><%= I18n.t("global.link_to.marketing_support").html_safe %></p>
            </div>
            <div class="col-lg-4 app-features-list">
              <span>
                  <img src="<%= asset_path 'cp-ex-feat-11.svg' %>" width="45">
                </span>
                <p><%= I18n.t("global.link_to.performance_based").html_safe %></p>
            </div>
            <div class="col-lg-4 app-features-list">
              <span>
                  <img src="<%= asset_path 'cp-ex-feat-02.svg' %>" width="45">
                </span>
                <p><%= I18n.t("global.link_to.extensive_nurturing").html_safe %></p>
            </div>
            <div class="col-lg-4 app-features-list">
              <span>
                  <img src="<%= asset_path 'cp-ex-feat-04.svg' %>" width="45">
                </span>
                <p><%= I18n.t("global.link_to.crm_training").html_safe %></p>
            </div>
            <div class="col-lg-4 app-features-list">
              <span>
                  <img src="<%= asset_path 'cp-ex-feat-07.svg' %>" width="45">
                </span>
                <p><%= I18n.t("global.link_to.fully_automated").html_safe %></p>
            </div>
            <div class="col-lg-4 app-features-list">
              <span>
                  <img src="<%= asset_path 'cp-ex-feat-08.svg' %>" width="45">
                </span>
                <p><%= I18n.t("global.link_to.online_inventory_selection").html_safe %></p>
            </div>
            <div class="col-lg-4 app-features-list">
                <span>
                  <img src="<%= asset_path 'cp-ex-feat-09.svg' %>" width="45">
                </span>
                <p><%= I18n.t("global.link_to.complete_transparency").html_safe %></p>
            </div>
            <div class="col-lg-4 app-features-list">
              <span>
                  <img src="<%= asset_path 'cp-ex-feat-10.svg' %>" width="45">
                </span>
                <p><%= I18n.t("global.link_to.unique_online").html_safe %></p>
            </div>
            CPDashboard
        })
      end

      Template::UITemplate.where(booking_portal_client_id: client_id).count

      if Template::UITemplate.where(name: 'channel_partner/new/header').blank?
        Template::UITemplate.create({ booking_portal_client_id: client_id, subject_class: 'View', name: 'channel_partner/new/header', content: '<h1 class="sec-title text-center pt-2 pb-1">Get Started</h1> <p class="sec-desc text-center pb-2">Now is the best time to turn your dream into reality</p>', is_active: true })
      end
    end

    def self.project_based_seed(project_id, client_id)
      # To add links for videos
      if Template::UITemplate.where(name: 'assets/_videos', project_id: project_id, booking_portal_client_id: client_id).blank?
        Template::UITemplate.create({ booking_portal_client_id: client_id, project_id: project_id, subject_class: 'View', name: 'assets/_videos', content: '<div class="row">
          <div class="col-12 my-4 text-center">
          </div>
        </div>' })
      end

      if Template::UITemplate.where(name: 'sales_dashboard', project_id: project_id, booking_portal_client_id: client_id).blank?
        Template::UITemplate.create({ booking_portal_client_id: client_id, project_id: project_id, subject_class: 'View', name: 'sales_dashboard', content: '<section class=" mt-4">
          <div class="container">
            <div class="row">
              <div class="col-lg-12 mt-5">
                  <h2 class="sec-title after-line">Project Highlights</h2>
              </div>
            </div>
          </div>
        </section>' })
      end
    end
  end
end
