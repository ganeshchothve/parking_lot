# frozen_string_literal: true

# DatabaseSeeds::UITemplate.seed CLient.last.id
module DatabaseSeeds
  module UITemplate
    def self.seed(client_id)
      # To render card on user dashboard
      if Template::UITemplate.where(name: 'users/_welcome').blank?
        Template::UITemplate.create({ booking_portal_client_id: client_id, subject_class: 'View', name: 'users/_welcome', content: '
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

        <% if current_user.kyc_ready? && current_user.booking_details.in(status: BookingDetail::BOOKING_STAGES).count >= current_user.allowed_bookings %>
            <p class="white text-center fn-14 fn-500">You cannot book any more apartments as you have reached the maximum bookings allowed per customer.</p>
        <% elsif current_user.kyc_ready? && current_client.enable_actual_inventory?(current_user) %>
          <%= booking_detail = current_user.booking_details.hold.first %>
          <% if booking_detail && booking_detail.search %>
            <!-- <p class="white text-center fn-14 fn-500">You already have a unit on hold.</p> -->
            <%= link_to "Checkout using unit already held", checkout_user_search_path(booking_detail.search), class: "large-btn black-bg display-block fn-500 center-block show-kyc width-250" %>
          <% else %>
            <% if policy([current_user_role_group, ProjectUnit.new(user: current_user, status: "available")]).hold? %>
              <p class="white text-center fn-14 fn-500">Choose Apartment</p>
              <%= link_to t("controller.buyer.dashboard.book_apartment"), new_search_path, class: "large-btn black-bg display-block fn-500 center-block show-kyc" %>
            <% end %>
          <% end %>
        <% elsif current_user.kyc_ready? %>
          <!-- <p class="white text-center fn-14 fn-500">Make Payment to proceed further</p> -->
          <%= link_to t("controller.buyer.dashboard.add_payment"), new_buyer_receipt_path, class: "large-btn black-bg display-block fn-500 center-block show-kyc modal-remote-form-link" %>
        <% else %>
          <!-- <p class="white text-center fn-14 fn-500">Fill your KYC form to proceed further</p> -->
          <%= link_to t("controller.buyer.dashboard.fill_kyc_form"), new_buyer_user_kyc_path, class: "large-btn black-bg display-block fn-500 center-block show-kyc modal-remote-form-link" %>
        <% end%>' })
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
        <div class="container">
          <% if defined?(current_user) && current_user %>
            <div class="row pb-1 footer-tow-cmn">
              <div class="col-lg-6 col-md-8 col-xs-6 col-sm-4 no-pd">
                <ul class="footer-menu float-left mb-0">
                  <%= bottom_navigation %>
                </ul>
              </div>
              <div class="col-lg-6 col-md-4 col-xs-6 col-sm-8 no-pd">
                <ul class="footer-menu float-right mb-0">
                  <%= render "layouts/language" %>
                </ul>
              </div>
            </div>
          <% end %>
          <div class="row scroll-footer">
            <% if defined?(current_user) && current_user %>
              <hr class="w-100 m-0">
            <% end %>
            <div class="col-lg-8 no-pd">
              <div class="footer-top footer-menu">
                <p class="m-0 pb-1"><%= current_project.name %> is registered via MahaRERA No.: <%= current_project.rera_registration_no %> & is available on <a href="https://maharera.mahaonline.gov.in" target="_blank">https://maharera.mahaonline.gov.in</a>.</p>
              </div>
            </div>
            <% unless defined?(current_user) && current_user %>
              <div class="col-lg-4 col-md-4 col-xs-12 col-sm-12 no-pd">
                <ul class="footer-menu float-right mb-0">
                  <%= render "layouts/language" %>
                </ul>
              </div>
            <% end %>
          </div>
        </div>' })
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

      # To change image on unit selection filters page
      if Template::UITemplate.where(name: 'searches/new').blank?
        Template::UITemplate.create({ booking_portal_client_id: client_id, subject_class: 'View', name: 'searches/new', content: '<% image = Asset.where(asset_type: "unit_selection_filter_image").first %>
          <% if image.present? %>
            <%= image_tag "#{image.file_name}", class: "rounded img-fluid", width: 400, height: 400 %>
          <% end %>
        ' })
      end

      # To change image on login page
      if Template::UITemplate.where(name: 'login_page_image').blank?
        Template::UITemplate.create({ booking_portal_client_id: client_id, subject_class: 'View', name: 'login_page_image', content: '
          <% image = Asset.where(asset_type: "login_image").first %>
          <% if image.present? %>
            <% @login_image_path = image.file_name %>
          <% end %>' })
      end

      Template::UITemplate.where(booking_portal_client_id: client_id).count
    end
  end
end
