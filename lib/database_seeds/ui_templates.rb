# frozen_string_literal: true

# DatabaseSeeds::UITemplate.seed CLient.last.id
module DatabaseSeeds
  module UITemplate
    def self.seed(client_id)
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

      if Template::UITemplate.where(name: 'devise/sessions/new').blank?
        Template::UITemplate.create({ booking_portal_client_id: client_id, subject_class: 'View', name: 'devise/sessions/new', content: '<h1 class="mt-0 fn-24">Welcome to <%= current_project.name %></h1>
          <p class="p-style mt-0">Now is the best time to turn your dream into reality</p>
          <p class="p-style"><strong>Login</strong> to Book an Apartment online</p>' })
      end

      if Template::UITemplate.where(name: 'home/register').blank?
        Template::UITemplate.create({ booking_portal_client_id: client_id, subject_class: 'View', name: 'home/register', content: '<h1 class="mt-0 fn-20">Biggest real estate opportunity in Pune<br> Introducing exclusive <%= ProjectUnit.distinct(:unit_configuration_name).map {|x| x.match(/\d*.*\d/).to_s}.uniq.sort.first(3).to_sentence(last_word_connector: " & ") %> Bed residences starting from <%= number_to_indian_currency(DashboardDataProvider.minimum_agreement_price.to_s.match(/(\d+)\d{5}/).try(:captures).try(:first)) %> lakhs</h1>
        <p class="p-style">Home buying can’t get better than this</p>
        <p><strong>Register Now</strong> to Book Online</p>' })
      end

      Template::UITemplate.where(booking_portal_client_id: client_id).count
    end
  end
end
