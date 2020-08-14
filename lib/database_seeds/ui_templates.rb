# frozen_string_literal: true

# DatabaseSeeds::UITemplate.seed CLient.last.id
module DatabaseSeeds
  module UITemplate
    def self.seed(client_id)
      # To add links for videos
      if Template::UITemplate.where(name: 'assets/_videos').blank?
        Template::UITemplate.create({ booking_portal_client_id: client_id, subject_class: 'View', name: 'assets/_videos', content: '<div class="row">
          <div class="col-12 my-4 text-center">
            <iframe width="560" height="315" src="https://www.youtube.com/embed/B0NJRlfr68g" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
          </div>
          <div class="col-12 mb-4 text-center">
            <iframe width="560" height="315" src="https://www.youtube.com/embed/BQcCuwyIwDs" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
          </div>
          <div class="col-12 mb-4 text-center">
            <iframe width="560" height="315" src="https://www.youtube.com/embed/6-EpvQP5G3g" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
          </div>
        </div>' })
      end

      # To render card on user dashboard
      if Template::UITemplate.where(name: 'users/_welcome').blank?
        Template::UITemplate.create({ booking_portal_client_id: client_id, subject_class: 'View', name: 'users/_welcome', content: '
        <div class="col-lg-12 col-md-12 col-sm-12 col-xs-12 bg-gradient">
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
              <div class = "col">
                <% if current_user.kyc_ready? && current_user.booking_details.in(status: BookingDetail::BOOKING_STAGES).count >= current_user.allowed_bookings %>
                    <p class="white text-center fn-14 fn-500">You cannot book any more apartments as you have reached the maximum bookings allowed per customer.</p>
                <% elsif current_user.kyc_ready? && current_client.enable_actual_inventory?(current_user) %>
                  <%= booking_detail = current_user.booking_details.hold.first %>
                  <% if booking_detail && booking_detail.search %>
                    <!-- <p class="white text-center fn-14 fn-500">You already have a unit on hold.</p> -->
                    <%= link_to "Checkout using unit already held", checkout_user_search_path(booking_detail.search), class: "large-btn black-bg display-block fn-500 center-block show-kyc width-250" %>
                  <% else %>
                    <% if policy([current_user_role_group, ProjectUnit.new(user: current_user, status: "available")]).hold? %>
                      <!-- <p class="white text-center fn-14 fn-500">Choose Apartment</p> -->
                      <%= link_to t("controller.buyer.dashboard.book_apartment"), new_search_path, class: "large-btn black-bg display-block fn-500 center-block show-kyc" %>
                    <% end %>
                  <% end %>
                <% elsif current_user.kyc_ready? %>
                  <!-- <p class="white text-center fn-14 fn-500">Make Payment to proceed further</p> -->
                  <%= link_to t("controller.buyer.dashboard.add_payment"), new_buyer_receipt_path, class: "large-btn black-bg display-block fn-500 center-block show-kyc modal-remote-form-link" %>
                <% else %>
                  <!-- <p class="white text-center fn-14 fn-500">Fill your KYC form to proceed further</p> -->
                  <%= link_to t("controller.buyer.dashboard.fill_kyc_form"), new_buyer_user_kyc_path, class: "large-btn black-bg display-block fn-500 center-block show-kyc modal-remote-form-link" %>
                <% end%>
              </div>
            </div>
          </div>
        </div>' })
      end

      # To render projects section card on user dashboard
      if Template::UITemplate.where(name: 'project_units/_section').blank?
        Template::UITemplate.create({ booking_portal_client_id: client_id, subject_class: 'View', name: 'project_units/_section', content: '
        <div class="col-lg-12 col-xs-12 col-md-12 col-sm-12 my-4 no-pd">
          <div class="box-card">
            <div class="box-header bg-gradient-cd br-rd-tr-4">
              <h2 class="title icon-set icon-building-white">
                <%= Project.model_name.human %>
              </h2>
            </div>
            <div class="project-slider1">
              <div>
                <div class="box-content br-rd-bl-4 bg-white text-center">
                  <h3 class="title"><%= current_project.name %></h3>
                  <p class="sort-desc col-lg-6 col-xs-12 col-md-6 col-sm-12 offset-md-3 offset-lg-3"><%= t("dashboard.user.projects.sub_heading") %></p>
                  <ul class="prjt-info br-rd-4">
                    <li><span><%= t("dashboard.user.titles.available_inventory") %></span><p><%= DashboardDataProvider.available_inventory %></p></li>
                    <li><span><%= t("mongoid.attributes.search.starting_price") %></span><p><%= number_to_indian_currency(DashboardDataProvider.minimum_agreement_price) %></p></li>
                    <li><span><%= t("mongoid.attributes.project_unit.configuration") %></span><p><%= DashboardDataProvider.configurations.to_sentence(last_word_connector: " & ") %></p></li>
                  </ul>
                  <% if current_client.brochure.present? %>
                    <ul class="prjt-link">
                      <li><%= link_to t("dashboard.user.titles.download_brochure"), download_brochure_path, class: "text-uppercase" %></li>
                    </ul>
                  <% end %>
                  <%= link_to "Visit Website >", current_client.website_link, target: "_blank", class: "large-btn bg-light-blue display-block fn-500 center-block text-uppercase" %>
                </div>
              </div>
            </div>
          </div>
        </div>' })
      end

      # To render card on user dashboard
      if Template::UITemplate.where(name: 'index/_channel_partner').blank?
        Template::UITemplate.create({ booking_portal_client_id: client_id, subject_class: 'View', name: 'index/_channel_partner', content: '
        <div class="col-lg-12 col-xs-12 bg-gradient-cd br-rd-8 col-md-12 col-sm-12">
          <img src="<%= asset_path \'quality-tag.png\' %>" alt="user icon" class="quality-tag">
          <div class="row">
            <div class="col-lg-8 col-md-12 col-sm-12 col-xs-12 offset-lg-2">
              <div class="box-content">
                <h1 class="wc-title white text-center">Welcome <%= current_user.name %></h1>
                <p class="white text-center fn-300 fn-18">Follow these quick steps and get your customers to be one of the privileged few to own a home at <%= current_project.name %></p>
                <ul class="step-booking">
                  <li class="light-blue">
                    <span>
                      <%= image_tag "file-invoice-lightblue.svg", alt: "Add customer" %>
                    </span>Add Customers
                  </li>
                  <li class="light-blue">
                    <span><%= image_tag "rupee-lightblue.svg" %></span>Pay Remaining Amount
                  </li>
                  <li class="light-blue">
                    <span><%= image_tag "building-lightblue.svg" %></span><%= BookingDetail.model_name.human %>
                  </li>
                </ul>
                <!-- <p class="white text-center fn-14 fn-500">Fill your KYC form for proceed further</p> -->
                <div class="row">
                  <div class="col">
                    <%= link_to "Add Customer", new_admin_user_path(role: "user"), class: "large-btn black-bg display-block fn-500 center-block show-kyc modal-remote-form-link" %>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>' })
      end

      # To render card on sales & admin dashboard
      if Template::UITemplate.where(name: 'dashboard/index/_admin').blank?
        Template::UITemplate.create({ booking_portal_client_id: client_id, subject_class: 'View', name: 'dashboard/index/_admin', content: '
        <div class="col-lg-12 col-md-12 col-sm-12 col-xs-12 bg-gradient">
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
      if Template::UITemplate.where(name: 'devise/sessions/new').blank?
        Template::UITemplate.create({ booking_portal_client_id: client_id, subject_class: 'View', name: 'devise/sessions/new', content: '<h1 class="mt-0 fn-24">Welcome to <%= current_project.name %></h1>
          <p class="p-style mt-0">Now is the best time to turn your dream into reality</p>
          <p class="p-style"><strong>Login</strong> to Book an Apartment online</p>' })
      end

      # To change text on register page for user
      if Template::UITemplate.where(name: 'home/register').blank?
        Template::UITemplate.create({ booking_portal_client_id: client_id, subject_class: 'View', name: 'home/register', content: '<h1 class="mt-0 fn-20">Biggest real estate opportunity in Pune<br> Introducing exclusive <%= ProjectUnit.distinct(:unit_configuration_name).map {|x| x.match(/\d*.*\d/).to_s}.uniq.sort.first(3).to_sentence(last_word_connector: " & ") %> Bed residences starting from <%= number_to_indian_currency(DashboardDataProvider.minimum_agreement_price.to_s.match(/(\d+)\d{5}/).try(:captures).try(:first)) %> lakhs</h1>
        <p class="p-style">Home buying can’t get better than this</p>
        <p><strong>Register Now</strong> to Book Online</p>' })
      end

      # To change text on register page for channel_partner
      if Template::UITemplate.where(name: 'channel_partner/new').blank?
        Template::UITemplate.create({ booking_portal_client_id: client_id, subject_class: 'View', name: 'channel_partner/new', content: '<h1 class="mt-0 fn-20">We are a big family of 400+ esteemed partners and we are happy to onboard you</h1>
        <p><strong>Register now</strong> & join our network to explore new opportunities</p>' })
      end

      # To change text in the footer
      if Template::UITemplate.where(name: 'layouts/_navbar_footer').blank?
        Template::UITemplate.create({ booking_portal_client_id: client_id, subject_class: 'View', name: 'layouts/_navbar_footer', content: '
        <p class="m-0 pb-1"><%= current_project.name %> is registered via MahaRERA No.: <%= current_project.rera_registration_no %> & is available on <a href="https://maharera.mahaonline.gov.in" target="_blank">https://maharera.mahaonline.gov.in</a>.</p>' })
      end

      # To change text above timer when booking a unit
      if Template::UITemplate.where(name: 'searches/checkout').blank?
        Template::UITemplate.create({ booking_portal_client_id: client_id, subject_class: 'View', name: 'searches/checkout', content: '<p class="p-style white"> To be fair to other user interested in this apartments, we have held this unit for some time. Please go through the costs and payments schedule before you make a payment of <%= number_to_indian_currency(@project_unit.blocking_amount || current_client.blocking_amount) %></p>' })
      end

      # To change text on show booking detail for user & channel_partner
      # @bd is booking_detail
      if Template::UITemplate.where(name: 'booking_details/_details').blank?
        Template::UITemplate.create({ booking_portal_client_id: client_id, subject_class: 'View', name: 'booking_details/_details', content: '<ul>
            <li>You need to pay <%= number_to_indian_currency(@bd.project_unit.booking_price) %> to confirm the booking</li>
            <% unless current_client.cancellation_amount.zero? %>
              <li>Cancellation charges are <%= number_to_indian_currency(current_client.cancellation_amount) %></li>
            <% end %>
            <% if @bd.project_unit.auto_release_on %>
              <li>You have <%= (@bd.project_unit.auto_release_on - Date.today).to_i %> days (before <%= I18n.l(@bd.project_unit.auto_release_on) %>) remaining to confirm this booking. Please make a remaining payment of <%= number_to_indian_currency(@bd.pending_balance.round) %></li>
            <% end %>
          </ul>' })
      end

      if Template::UITemplate.where(name: 'quotation_pdf').blank?
        Template::UITemplate.create({ booking_portal_client_id: client_id, subject_class: 'View', name: 'quotation_pdf',
 content: <<-'QUOTATION_PDF'
            <div class='text-center'>
              <img src='<%= current_client.logo.url.try(:gsub, "https", "http") || '' %>' class='mb-3' width=120>
              <h2><%= current_project.name %></h2>
            </div>
            <%= render 'admin/project_units/project_unit_cost_details', locals: { booking_detail: @booking_detail } %>
            <%= @booking_detail.cost_sheet_template.parsed_content(@booking_detail) %>
            <%= @booking_detail.payment_schedule_template.parsed_content(@booking_detail) %>
          QUOTATION_PDF
        })
      end

      Template::UITemplate.where(booking_portal_client_id: client_id).count
    end
  end
end
