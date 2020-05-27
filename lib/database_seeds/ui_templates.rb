# frozen_string_literal: true

# DatabaseSeeds::UITemplate.seed CLient.last.id
module DatabaseSeeds
  module UITemplate
    def self.seed(client_id)
      # To render card on admin dashboard
      # if Template::UITemplate.where(name: 'users/_welcome').blank?
      #   Template::UITemplate.create({ booking_portal_client_id: client_id, subject_class: 'View', name: 'users_pwelcome', content: '
      #     <div class="box-content">
      #       <h1 class="wc-title white text-center"> <%= t("dashboard.user.welcome.heading", name: current_user.name) %> </h1>
      #       <% if current_user.receipts.present? && !current_client.enable_actual_inventory?(current_user) %>
      #         <p class="white text-center fn-300 fn-18"><%= t("dashboard.user.welcome.sub_heading_1") %></p>
      #       <% else %>
      #         <p class="white text-center fn-300 fn-18"><%= t("dashboard.user.welcome.sub_heading_html", project_size: current_project.project_size, blocking_amount: number_to_indian_currency(current_client.blocking_amount)) %></p>
      #       <% end %>
      #       <ul class="step-booking">
      #         <li>
      #           <%= link_to [:new, current_user_role_group, :user_kyc], class: "modal-remote-form-link" do %>
      #             <span><%= image_tag "file-invoice.svg", alt: "Invoice" %></span>
      #             <%= t("controller.user_kycs.new.link_name") %>
      #           <% end %>

      #         </li>
      #         <li>
      #           <%= link_to_if !current_user.user_kyc_ids.blank?, [:new, current_user_role_group, :receipt ], { class: "modal-remote-form-link"}, {} do %>
      #             <span><%= image_tag "rupee-blue.svg", alt: "Rupee" %></span>
      #             <%= t("controller.receipts.new.link_name") %>
      #           <% end %>
      #         </li>
      #         <li>
      #           <%= link_to_if policy([current_user_role_group, ProjectUnit.new(user: current_user, status: "available")]).hold?, new_search_path do %>
      #             <span><%= image_tag "get-token.svg", alt: "Building", style: "width:40px;" %></span>
      #             <%= t("dashboard.user.towers.header") %>
      #           <% end %>
      #         </li>
      #       </ul>

      #       <div class="row">
      #         <div class="col lg-3">
      #         </div>
      #         <div class="col lg-3">
      #           <% if current_user.kyc_ready? && current_user.booking_details.in(status: BookingDetail::BOOKING_STAGES).count >= current_user.allowed_bookings %>
      #               <p class="white text-center fn-14 fn-500">You cannot book any more apartments as you have reached the maximum bookings allowed per customer.</p>
      #           <% elsif current_user.kyc_ready? && current_client.enable_actual_inventory?(current_user) %>
      #             <%- booking_detail = current_user.booking_details.hold.first %>
      #             <% if booking_detail && booking_detail.search %>
      #               <!-- <p class="white text-center fn-14 fn-500">You already have a unit on hold.</p> -->
      #               <%= link_to t("controller.booking_details.continue_booking.link_name"), checkout_user_search_path(booking_detail.search), class: "large-btn black-bg display-block fn-500 center-block show-kyc width-250" %>
      #             <% else %>
      #               <% if policy([current_user_role_group, ProjectUnit.new(user: current_user, status: "available")]).hold? %>
      #                 <p class="white text-center fn-14 fn-500"><%= t("controller.searches.towers.header") %></p>
      #                 <%= link_to t("controller.buyer.dashboard.book_apartment"), new_search_path, class: "large-btn black-bg display-block fn-500 center-block show-kyc" %>
      #               <% end %>
      #             <% end %>
      #           <% elsif current_user.kyc_ready? %>
      #             <!-- <p class="white text-center fn-14 fn-500">Make Payment to proceed further</p> -->
      #             <%= link_to t("controller.buyer.dashboard.add_payment"), new_buyer_receipt_path, class: "large-btn black-bg display-block fn-500 center-block show-kyc modal-remote-form-link" %>
      #           <% else %>
      #             <!-- <p class="white text-center fn-14 fn-500">Fill your KYC form to proceed further</p> -->
      #             <%= link_to t("controller.buyer.dashboard.fill_kyc_form"), new_buyer_user_kyc_path, class: "large-btn black-bg display-block fn-500 center-block show-kyc modal-remote-form-link" %>
      #           <% end%>
      #         </div>
      #         <div class="col lg-3">
      #           <% if policy([current_user_role_group, current_user]).loan_eligibility_details? %>
      #             <%= link_to "Check Loan Eligibility Details", loan_eligibility_details_buyer_user_path(current_user.id), class: "large-btn black-bg display-block fn-500 center-block show-kyc width-250 modal-remote-form-link" %>
      #           <% end %>
      #         </div>
      #         <div class="col lg-3">
      #         </div>
      #       </div>
      #     </div>' })
      # end

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

      # To change text on show booking detail for user
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

      Template::UITemplate.where(booking_portal_client_id: client_id).count
    end
  end
end
