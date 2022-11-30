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
        <% if current_project.rera_registration_no %> <p class="m-0 pb-1"><%= current_project.name %> is registered via MahaRERA No.: <%= current_project.rera_registration_no %> & is available on <a href="https://maharera.mahaonline.gov.in" target="_blank">https://maharera.mahaonline.gov.in</a>.</p> <% end %>' })
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
		<h1>Terms and Conditions:</h1>
    <p>Thank you for visiting partners.beyondwalls.com (the “<strong>Website</strong>”), which is owned, operated and managed by Amura Marketing Technologies Limited, incorporated under the Companies Act 1956 whose registered office is at 3rd Floor, Sr. No. 9, H.No:1/2, Near Ramada Plaza, Above Maruti Suzuki Suman Kirti Cars Pvt. Ltd., Mahalunge, Pune, Maharashtra 411045 (hereinafter referred to as, “<strong>Company</strong>”, which expression shall, unless it be repugnant to the context or meaning thereof, be deemed to mean and include all its successors and permitted assigns).</p>
    <p>This Agreement sets forth the following legally binding terms and conditions contained in these Terms of Use, together with any documents incorporate by reference including Privacy Policy available at https://partners.beyondwalls.com/privacy-policy,and all other operating rules, policies, and procedures that may be published on the Website by the Company, which are incorporated by reference (collectively referred to as the “Agreement”), which govern your access to and use of the Website and any content, functionality, sub-domains and services offered on or through the same.</p>
		<h2>DEFINITIONS</h2>
		<p>The words and phrases used in the Terms of Use are defined as under unless repugnant to the context or meaning thereof:</p>
		<ul>
			<li>“Agreement” shall mean the Agreement between the Company and User with terms and conditions as provided herein and includes the Privacy Policy and all the schedules, appendices and references mentioned herein with all such amendments as affected by the Company from time to time.</li>
			<li>“Company” shall mean “Amura Marketing Technologies Limited”.</li>
      <li>“Website” shall mean the online marketplace designed, developed, owned and operated solely by Amura Marketing Technologies Limited and located at partners.beyondwalls.com or such other URL as may be specifically provided by Amura Marketing Technologies Limited.</li>
			<li>“Products”/ “Services” are BeyondWalls offered by Amura Marketing Technologies.</li>
			<li>“User(s)” or “Buyer(s)” shall mean any natural or legal person who accesses, uses, deals with and/or transact at the Website in any way.</li>
		</ul>
		<h2>ACCEPTANCE OF TERMS OF USE:</h2>
		<ul>
			<li>The Agreement between the Company and the User is an electronic record in terms of Information Technology Act, 2000 (as amended by the Information Technology (Amendment) Act, 2008) and rules made there pertaining to electronic records in various statutes. The Agreement is generated as an electronic record by a computer system and does not require any physical or digital signatures and is also published in accordance with the provisions of Rule 3(1) of the Information Technology (Intermediaries guidelines) Rules, 2011.</li>
			<li>Use of this Website is regulated by Terms & Conditions provided herein. In addition, some services offered through the Website may be subject to additional terms and conditions adopted by the Company. Your use of those services is subject to those additional terms and conditions, which are incorporated into these Terms of Use by this reference.</li>
			<li>By accessing, browsing, dealing, transacting and/or otherwise using this Website, you shall be deemed to have accepted these Terms of Use and the Agreement. In the event, an option is given during the course of every transaction / check-out to enable the User to express his/her acceptance or rejection of the Agreement, your acceptance by clicking on “I Agree” shall be deemed that you have gone through, understood and accepted these terms and conditions completely and accordingly the Agreement shall be treated as legally binding and enforceable agreement between the Company and you. In case if you do not agree with any of these Terms & Conditions or all of the Agreement, then you are not authorized to view, access, deal and/or transact on this Website.</li>
			<li>Your use of this Website (including, without limitation, all content, software, functions, services, materials and information made available or described on this Website or accessed by means thereof), and any marketing or promotional activities or any other item or service provided via this Website (“<strong>ancillary service</strong>”), is at your sole risk. The Website is provided on an “as is” and “as available” basis.</li>
			<li>The information, Products link offered on this Website, is solely for the User’s information and subject to the User’s acceptance without modification of the terms, conditions and notices contained herein and should not be considered as a substitute for professional advice. The Company, its affiliate companies, associate companies, consultants, contractors, advisors, accountants, agents and/ or suppliers assume no responsibility for any consequence relating directly and/or indirectly to any action and/or inaction that the User takes based on the information, Services and Products offered on this Website. The Company is not responsible for the information relating to the various products offered by Sellers on this Website and makes no representation as to accuracy, completeness of the same. The Company, its affiliates, associate companies, accountants, advisors, agents, consultants, contractors and suppliers cannot guarantee, and will not be responsible for any damage and/or loss related to, the accuracy, completeness or timelines of the information.</li>
			<li>The Company has no special relationship with or fiduciary duty to you. You acknowledge that we have no duty to take any action regarding any of the following: which users gain access to the Website; what content users access through the Website; what affects the content may have on users; how users may interpret or use the content; or what actions users may take as a result of having been exposed to the content. We cannot guarantee the authenticity of any data or information that Sellers provide about themselves or their campaigns and projects. You release us from all liability for your having acquired or not acquired content through the Website. The Website may contain, or direct you to websites containing, information that some people may find offensive or inappropriate. We make no representations concerning any content on the Website, and we are not liable for the accuracy, copyright compliance, legality, or decency of material contained on the service.</li>
		</ul>
		<h2>ELIGIBILITY TO TRANSACT ON THE WEBSITE:</h2>
		<ul>
			<li>Use of the Website is available only to natural and / or legal persons who can form legally binding contracts under Indian Contract Act, 1872. Persons who are “incompetent to contract” within the meaning of the Indian Contract Act, 1872 including minors, un-discharged insolvents etc. are not eligible to use the Website in any manner. If you are a minor i.e. under the age of 18 years, you shall not register as a User of the Website and shall not transact on or use the Website. As a minor if you wish to use or transact on the Website, such use or transaction may be only made by your legal guardian or parents on your behalf on the Website. Company reserves the right to terminate your membership and / or refuse to provide you with access to the Website if it is brought to Company’s notice or if it is discovered that you are under the age of 18 years. The Company reserves the right to initiate legal action against any person who solicits a minor to register as an User on the Website, even after knowledge that he/she is under the age of 18 years.</li>			
		</ul>
		<h2>PLATFORM FOR TRANSACTION AND COMMUNICATION AND CONDITION FOR ONLINE BLOCKING:</h2>
		<ul>
      <li>When you block an inventory on partners.beyondwalls.com, you will receive an e-mail confirming receipt of your order and containing the details of your order (the “Unit Blocking Confirmation E-mail”). The Unit Blocking Confirmation e-mail is acknowledgement that Seller has received your order, and does not confirm acceptance of your offer to block the inventory. Company will only accept your offer temporarily for 7 days, and conclude the contract of sale for a Project blocked by you, when the first installment or Initial down payment is processed on Site of Project/Nearest Designated Sales Office or any Online Medium directed and transaction monetized to the respected subsidiary company.</li>
			<li>An e-mail confirmation is sent to you that the project has been blocked and you will be certified as a customer post the Initial agreed down payment for any listed project on website. You confirm that the Projects(s) blocked by you are purchased for your internal / personal purpose and not for re-sale. You authorize us to declare and provide declaration to any governmental authority on your behalf stating the aforesaid purpose of the Products ordered by you on the Website. You can cancel your order for a Project as per Cancellation Policy.</li>
			<li>We may share customer information related to those transactions with that third-party. You should carefully review their privacy statements and other conditions of use.</li>
			<li>We will not be responsible for any business loss (including loss of profits, revenue, contracts, anticipated savings, data, goodwill or wasted expenditure) or any other indirect or consequential loss that is not reasonably foreseeable to both you and us when you commenced using the Website.</li>
			<li>We further expressly disclaim any warranties or representations (express or implied) in respect of quality, suitability, accuracy, reliability, completeness, timeliness, performance, safety, merchantability, fitness for a particular purpose, or legality of the Products listed or displayed or transacted or the content (including product information and/or specifications) on the Website. While we have taken precautions to avoid inaccuracies in content, information, software, Products, Services and related graphics, the responsibility & ownership of the content lie with the Seller. At no time shall any right, title or interest in the Products sold through or displayed on the Website vest with the Company nor shall the Company have any obligations or liabilities in respect of any transactions on the website.</li>
		</ul>
		<h2>RIGHT OF COMPANY TO AMEND TERMS:</h2>
		<ul>
			<li>We may revise and update these Terms of Use from time to time in our sole discretion. All changes are effective immediately when we post them and apply to all access to and use of the Website thereafter. We will not be liable if for any reason all or any part of the Website is unavailable at any time or for any period. From time to time, we may restrict access to some parts of the Website, or the entire Website, to users, including registered users.</li>
			<li>Your continued use of the Website following the posting of revised Terms of Use means that you accept and agree to the changes. You are expected to check this page from time to time/frequently/each time you access this Website so you are aware of any changes, as they are binding on you.</li>
		</ul>
		<h2>REGISTRATION, DATA AND OBLIGATIONS:</h2>
		<ul>
			<li>To access the Website or some of the resources it offers, you may be asked to provide certain registration details or other information. It is a condition of your use of the Website that all the information you provide on the Website is correct, current and complete. You agree that all information you provide to register with this Website or otherwise, including but not limited to through the use of any interactive features on the Website, is governed by our Privacy Policy, and you consent to all actions we take with respect to your information consistent with our Privacy Policy.</li>
			<li>If you choose, or are provided with, a user name, password or any other piece of information as part of our security procedures, you must treat such information as confidential, and you must not disclose it to any other person or entity under any circumstances, whatsoever. You also acknowledge that your account is personal to you and agree not to provide any other person with access to this Website or portions of it using your user name, password or other security information. You agree to notify us immediately of any unauthorized access to or use of your user name or password or any other breach of security. You also agree to ensure that you exit/logout from your account at the end of each session. You should use particular caution when accessing your account from a public or shared computer so that others are not able to view or record your password or other personal information.</li>
			<li>The Company shall be entitled to verify details furnished by you, if it deems fit, and in case any information furnished is found incorrect, false or misleading and if, in our opinion, you have violated any provision of these Terms of Use then the Company shall have the right to disable any user name, password or other identifier, whether chosen by you or provided by us, at any time in our sole discretion for any or no reason.</li>
			<li>You shall further be liable to be prosecuted and/or punished under applicable laws for furnishing false, incorrect, incomplete and/or misleading information to the Company. You shall indemnify and hold harmless the Company, its subsidiaries, affiliates and their respective officers, directors, agents and employees, from any claim or demand, or actions including reasonable attorney’s fees, made by any third party or penalty imposed due to or arising out of your breach of these Terms of Use or any document incorporated by reference, or your violation of any law, rules, regulations or the rights of a third party.</li>
			<li>You hereby expressly release the Company and/or its affiliates and/or any of its officers and its representatives from any cost, damage, liability or other consequence of any of the actions/inactions of the vendors and specifically waiver any claims or demands that you may have in this behalf under any statute, contract or otherwise.</li>
		</ul>
		<h2>INTELLECTUAL PROPERTY RIGHTS NOTICE</h2>
		<p>Copyright © Amura Marketing Technologies Limited. ALL RIGHTS RESERVED.</p>
		<ul>
			<li>The Company is the sole and exclusive owner / licensee and / or proprietor of all copyrights, designs, patents, trademarks, service marks, trade secrets, know-how, technical information and any other form of intellectual property rights and other proprietary rights with respect to the Website, including without limitation to such as text, graphics, images, logos, button icons, images, audio clips, video clips, digital downloads, data compilations, source code, reprographics, demos, patches, other files and software) forming part of the Website (“Company IPR”). You shall not use any of the Company IPR without prior written consent from the Company.</li>
			<li>All other trademarks, copyrights with respect to the various Products / Services for sale through the Website shall remain the exclusive intellectual property of their respective owners and the Company shall not claim any rights, benefits, interest or affiliation in connection with such intellectual property, unless otherwise expressly provided for.</li>
			<li>Nothing on the Website or your use of any of the Services shall be construed as conferring any license or other rights in the Company IPR, or any third party, whether implied or otherwise, save as expressly provided.</li>
			<li>Any Photographs/ software, including codes or other materials that are made available to download from the Website, is the copyrighted work of Amura Marketing Technologies Limited and/or its suppliers and affiliates. If you download software from the Website, use of the software is subject to the license terms in the software license agreement that accompanies or is provided with the software. You may not download or install the software until you have read and accepted the terms of the applicable software license agreement. Without limiting the foregoing, copying or reproduction of the software to any other server or location for further reproduction or redistribution is expressly prohibited unless otherwise provided for in the applicable software license agreement in the case of software, or the express written consent of the Company in the case of codes or other downloadable materials.</li>
			<li>You shall not create or attempt to create any domain names or solicit for creating such domain names which are identical/ deceptively similar to the Website. You shall not also engage in activities such as deep linking/ hyper linking on web pages of the Website. The Company reserves the right to initiate any action as it may deem fit, in case of any of the aforesaid activities similar to the Website.</li>
			<li>You agree that the contents appearing on the Website and the Products may be protected by copyrights, trademarks, service marks, patents, trade secrets, or other rights and laws including intellectual property rights. You shall abide by and maintain all copyright and other legal notices, information, and restrictions contained in the Website.</li>
			<li>The Agreement permits you to use the Website for your personal use only and you must not access or use any part of the Website or any services or materials available through the Website for any commercial purposes. You must not reproduce, distribute, modify, create derivative works of, publicly display, publicly perform, republish, download, store, disseminate or transmit any of the material on our Website, in any electronic or non-electronic form, nor included in any public or private electronic retrieval system or service.</li>
			<li>If you print, copy, modify, download or otherwise use or provide any other person with access to any part of the Website in breach of the Terms of Use, your right to use the Website will cease immediately and you must, at our option, return or destroy any copies of the materials you have made. No right, title or interest in or to the Website or any content on the site is transferred to you, and all rights not expressly granted are reserved by the Company. Any use of the Website not expressly permitted by these Terms of Use is a breach of these Terms of Use and may violate copyright, trademark and other laws.</li>
		</ul>
		<h2>CHARGES:</h2>
		<ul>
			<li>Access to the Website is free and the Company does not charge any fee for browsing the Website. Company reserves the right to change its fee policy from time to time. In particular, Company may at its sole discretion introduce new Services / Products and modify some or all of the existing Product/services offered on the Website. Unless otherwise stated, all fees shall be quoted in Indian Rupees. You shall be solely responsible for compliance of all applicable laws including those in India for making payments to the Company.</li>
		</ul>
		<h2>REPRESENTATION AND WARRANTY ON BEHALF OF THE COMPANY:</h2>
		<ul>
			<li>The Company does not represent or warrant as to specifics such as quality, value or saleability of the Products/Services offered to be sold or purchased on the Website. The Company also does not implicitly or explicitly support or endorse the sale or purchase of any Products or Services on the Website. We are not liable for any errors or omissions. The Company shall not be responsible in any manner whatsoever for (a) delivery of statement at wrong email address furnished by you; (b)any loss and/or damage to you due to incorrect, incomplete and/or false information furnished by you; or (c)any deficiency in payment of consideration payable towards the Products purchased on the Website.</li>
		</ul>
		<h2>REPRESENTATION AND WARRANTY ON BEHALF OF THE USER:</h2>
		<ul>
			<li>User represents and warrants that User is the owner and/or authorized to share the information. User gives on the Website and that the information is correct, complete, accurate, not misleading, does not violate any law, notification, order, circular, policy, rules and regulations, is not injurious to any person or is discriminatory with respect to sex, caste, race or religion and/or property.</li>
			<li>User undertakes to indemnify and keep indemnified the Company and/or its shareholders, directors, employees, officers, affiliates, associate companies, advisors, accountants, agents, consultants, contractors and/ or suppliers for all claims resulting from information User posts and/or supplies to the Company. The Company shall be entitled to remove any such information posted by User without any prior intimation to User.</li>
			<li>User understands that the Company does not have any control on accuracy of information submitted by anybody on the Website and therefore agrees that the Company shall not be responsible for any loss, damage, cost, expenses etc due to inaccuracy of any information submitted by User or anybody else on the Website.</li>
			<li>User shall not upload on the Website or otherwise distribute or publish through the Website any matter or material which is or may be considered abusive, pornographic, illegal, defamatory, obscene, racist or which is otherwise unlawful or designed to cause disruption to any computer systems or network. The Company shall be entitled without liability to the User and at our discretion to remove any such content from our server immediately. No user shall post any message to the Website which is in violation of the acceptable use policies in respect of this Website. We reserve the right to delete and remove all such postings.</li>
			<li>In the event, User is required to submit his/her information on the Website (“User Submissions”), User agrees and undertakes that the User shall be solely responsible for the same and confirms that such User Submissions :
				<ul>
					<li>is complete, correct, relevant and accurate</li>
					<li>is not fraudulent.</li>
					<li>does not infringe any third party’s intellectual property, trade secret and/or other proprietary rights and/or privacy.</li>
					<li>shall not be defamatory, libelous, unlawfully threatening and/or unlawfully harassing.</li>
					<li>shall not be indecent, obscene and/or contain any thing which is prohibited under any prevailing laws, rules & regulations, order of any court, forum, statutory authority.</li>
					<li>shall not be seditious, offensive, abusive, liable to incite racial, ethnic and/or religious hatred, discriminatory, menacing, tortuous, scandalous, inflammatory, blasphemous, in breach of confidence, in breach of privacy and/or which may cause annoyance and/or inconvenience.</li>
					<li>shall not constitute and/or encourage conduct that would be considered a criminal offence, give rise to civil liability, and/or otherwise be contrary to the law.</li>
					<li>(h) shall not be technically harmful (including, without limitation, computer/ mobile viruses, worms, or any other code or files) or other computer programming routines that may damage, destroy, limit, interrupt, interfere with, diminish value of, surreptitiously intercept or expropriate the functionality of any system, data or personal information.</li>
					<li>shall not create liability for the Company or cause the Company to lose the services of the Company’s ISPs or other suppliers. vis not in the nature of political campaigning, unsolicited or unauthorized advertising, promotional and/ or commercial solicitation, chain letters, mass mailings and/or any form of ‘spam’ or solicitation.</li>
					<li>is not illegal in any other way.</li>
				</ul>
			</li>
			<li>
				You grant to the Company the worldwide, non-exclusive, perpetual, irrevocable, royalty-free, sub licensable, transferable right to (and to allow others acting on its behalf) to,
				<ul>
					<li>use, edit, modify, prepare derivative works of, reproduce, host, display, stream, transmit, playback, transcode, copy, feature, market, sell, distribute, and otherwise fully exploit your User Submissions and your trademarks, service marks, slogans, logos, and similar proprietary rights, if any, in connection with (a) the Products, (b) the Company’s (and its successors’ and assigns’) businesses, (c) promoting, marketing, and redistributing part or all of the Website (and derivative works thereof) in any media formats and through any media channels (including, without limitation, third-party websites);</li>
					<li>take whatever other action is required to perform and market the Service;</li>
					<li>allow its Users to stream, transmit, playback, download, display, feature, distribute, collect, and otherwise use the User Submissions in connection with the Products; and</li>
					<li>use and publish, and permit others to use and publish, the User Submissions, names, likenesses, and personal and biographical materials of User, in connection with the provision or marketing of the Service. The foregoing license grant to the Company does not affect your other ownership or license rights in your User Submissions, including the right to grant additional licenses to your User Submissions. Further, the User agrees and understands that the Company reserves the right to remove and/or edit such User Submissions or part thereof.</li>
				</ul>
			</li>
			<li>User confirms that he/she shall abide by all notices and all the terms and conditions (as amended from time to time) contained and mentioned herein.</li>
			<li>User undertakes and confirms that User shall not use the Company’s Website, Products and/or services therein for any purpose that is unlawful and/or prohibited by the terms of the Agreement and/or under any applicable laws. User shall not use the Website and/or services therein in any manner which could damage, disable, overburden and/or impair the Website and/or any services therein and/or the network(s) connected to the Website and interfere with other User’s use and enjoyment of the Website and/or services therein.</li>
			<li>User shall not attempt to gain unauthorized access to any service on the Website, other Users’ Account(s), Computer systems and/or networks connected to the Website through hacking, phishing, password mining and/or any other means. User shall not attempt to obtain any materials or information through any means not intentionally made available to User through the Website. 10. The Company disclaims its responsibility for the content, accuracy, conformity to applicable laws of such material. Responsibility for ensuring that material submitted for inclusion on the Website complies with applicable laws is exclusively on such Users and advertisers and the Company will not be responsible for any claim, error, omission and/or inaccuracy in advertising material. The Company reserves the right to omit, suspend and/or change the position of any advertising material submitted for insertion.</li>
		</ul>
		<h2>TERMINATION:</h2>
		<ul>
			<li>The Company may, at any time, terminate or suspend any and all services and/ or access to the Website immediately, without prior notice and/or liability. The services and/ or access to the Website may also be terminated or suspended if:</li>
			<li>User breaches any of the terms or conditions of the Agreement and/or other incorporated agreements and/or guidelines.</li>
			<li>Requests by law enforcement and/or other government agencies.</li>
			<li>Discontinuance and/or material modification to the Website and/ or service (or any part thereof).</li>
			<li>Unexpected technical and/or security issues and/or problems.</li>
			<li>Engagement by the User in fraudulent and/or illegal activities.</li>
			<li>Non-payment of any fees owed by the User in connection with the use of Website and/ or services.</li>
			<li>Termination of User account includes:</li>
			<li>Removal of access to all offerings within the service.</li>
			<li>Deletion of User password and all related information, files and content associated with or inside User account (or any part thereof).</li>
			<li>Barring further use of the Website and/ or service.</li>
			<li>Further, the User agrees that all terminations for cause shall be made in Company’s sole discretion and that Company shall not be liable to the User or any third party for any termination of User account, any associated email address, or access to the services. Any fees paid hereunder are non-refundable. All provisions of this Agreement which by their nature should survive termination shall survive termination, including, without limitation, ownership provisions and warranty disclaimers.</li>
			<li>We also reserve our right to enforce appropriate sanctions against any of the Users of the Website who are responsible for abuse of the Website. Such sanctions may include, but are not limited to (a) a formal warning, (b) suspension of access through the Website or Products, (c) termination of any registration of the User with our Website or services.</li>
		</ul>
		<h2>LINKS TO OTHER WEBSITES:</h2>
		<p>We may update the content on this Website from time to time, but its content is not necessarily complete or up-to-date. Any of the material on the Website may be out of date at any given time, and we are under no obligation to update such material.</p>
		<p>If the Website contains links to other sites and resources provided by third parties, these links are provided for your convenience only. This includes links contained in advertisements, including banner advertisements and sponsored links. We have no control over the contents of those sites or resources, and accept no responsibility for them or for any loss or damage that may arise from your use of them.</p>
		<p>If you decide to access any of the third party websites linked to this Website, you do so entirely at your own risk and subject to the terms and conditions of use for such websites.</p>
		<p>The third party websites are not under Company’s control, and you acknowledge that the Company is not liable for the content, functions, accuracy, legality, appropriateness, or any other aspect of those other websites or resources. The inclusion on another website of any link to the Website does not imply endorsement by or affiliation with the Company. You further acknowledge and agree that the Company shall not be liable for any damage related to the use of any content, goods, or services available through any third-party website or resource. We are not responsible for examining or evaluating, and in no way make any endorsement, warranty, or representation relating to, the content of any such other website/ hyperlink, and will not be responsible or assume any liability for the actions, products, services, or content of any such other website or its related businesses. You acknowledge that framing the Website or any similar process is prohibited.</p>
		<h2>INDEMNIFICATION:</h2>
		<p>You agree to defend, indemnify and hold harmless the Company, its affiliates, licensors and service providers, and its and their respective officers, directors, employees, contractors, agents, licensors, suppliers, successors and assigns from and against any claims, liabilities, damages, judgments, awards, losses, costs, expenses or fees (including reasonable attorneys’ fees) made by any third party and/or penalty imposed due to and/or arising out of breach of the Agreement by User, and/or violation of any law, rules or regulations and/or the rights of a third party and/or the infringement by User including, without limitation, copyright and trademark infringement, obscene and/or indecent postings, and on-line defamation, and/or any third party using the User’s account, of any intellectual property and/or other right of any person and/or entity.</p>
		<h2>GOVERNING LAW AND JURISDICTION:</h2>
		<p>All matters relating to the Website and these Terms of Use and any dispute or claim arising therefrom or related thereto (in each case, including non-contractual disputes or claims) shall be governed by and construed in accordance with the laws of India and courts at Mumbai only shall have exclusive jurisdiction.</p>
		<h2>FORCE MAJEURE:</h2>
		<p>The Company shall not be liable for any failure and/or delay on its part in performing any of its obligation under this Agreement and/or for any loss, damage, costs, charges and expenses incurred and/or suffered by the User by reason thereof if such failure and/or delay shall be result of or arising out of Force Majeure Event set out herein. Explanation: “Force Majeure Event” means any event due to any cause beyond the reasonable control of the Company, including, without limitation, unavailability of any communication system, sabotage, fire, flood, earthquake, explosion, acts of God, civil commotion, strikes, lockout, and/or industrial action of any kind, breakdown of transportation facilities, riots, insurrection, hostilities whether war be declared or not, acts of government, governmental orders or restrictions, breakdown and/or hacking of the Website and/or contents provided for availing the Products and/or services under the Website, such that it is impossible to perform the obligations under the Agreement, or any other cause or circumstances beyond the control of the Company hereto which prevents timely fulfilment of obligation of the Company here under.</p>
		<h2>GENERAL PROVISION:</h2>
		<p>Waiver and Severability No waiver of by the Company of any term or condition set forth in these Terms of Use shall be deemed a further or continuing waiver of such term or condition or a waiver of any other term or condition, and any failure of the Company to assert a right or provision under these Terms of Use shall not constitute a waiver of such right or provision. If any provision of these Terms of Use is held by a court or other tribunal of competent jurisdiction to be invalid, illegal or unenforceable for any reason, such provision shall be eliminated or limited to the minimum extent such that the remaining provisions of the Terms of Use will continue in full force and effect.</p>
		<h2>ENTIRE AGREEMENT</h2>
		<p>The Terms of Use, Disclaimer and our Privacy Policy constitute the sole and entire agreement between You and Company with respect to the Website and supersede all prior and contemporaneous understandings, agreements, representations and warranties, both written and oral, with respect to the Website</p>
		<h2>E-MAIL SUBSCRIPTION</h2>
		<p>User can subscribe or opt-in for receiving email marketing mailers/newsletters in following cases:-</p>
		<ul>
			<li>When User registers from ‘Registration’ page: User clicks at the ‘Register’ link on Website header and registers by entering the email address and account password. User becomes subscribed for email marketing mailers or marketing SMS.</li>
			<li>When User registers during ‘Guest checkout’: While User is at the checkout stage, a non-registered user enters the email address & proceeds for payment. User is registered in the process and the password is emailed. Users become subscribed for email marketing mailers or marketing SMS.</li>
			<li>User subscribes from Static DIV, but User is not registered: When User visits Website for the first time, User will view a notification to submit the email address and subscribe for email marketing mailers. User is NOT registered but subscribed for email marketing mailers.</li>
			<li>User re-subscribes from ‘My Account’: This facility in ‘My Account’ where a registered User which is currently un-subscribed for email marketing mailers can select the option to receive such mailers in future. Such User is subscribed or opt-in.</li>
			<li>User subscribes from email marketing mailer: The email marketing mailer can be sent to an email address which is currently not subscribed or opt-in for the same. The marketing mailer would have link using which User can subscribe for receiving the similar mailers in future. Such User is subscribed.</li>
			<li>User is un-subscribed for receiving email marketing mailers/newsletters in following cases:-
				<ul>
					<li>User un-subscribes from email marketing mailer: Every email marketing mailer would have a link by using which User can un-subscribe from receiving any mailer in future. Such User is un-subscribed.</li>
					<li>User un-subscribes from ‘My Account’: This a facility in ‘My Account’ where a registered User already subscribed for email marketing mailers can unselect the option to receive such mailers in future. Such User is un-subscribed.</li>
				</ul>
			</li>
		</ul>
		<h2>GRIEVANCES</h2>
		<p>All service complaints relating to the functioning of the Website can be logged in through the Toll Free number, specified below, which will be attended by local service centre appointed by the Company.</p>
		<p>For detailed service policy and complaints about the delivery or functioning of Products, please refer Product manuals as may be formulated by the Sellers on their respective webpages.</p>
    <p>For any service related queries or complaints relating to the Website, please write us at : <a href="mailto:info@partners.beyondwalls.com">info@partners.beyondwalls.com</a></p>
    <p>Any other feedback, comments, requests for technical support and other communications relating to the Website also should be directed to <a href="mailto:info@partn.beyondwalls.comer">info@partners.beyondwalls.com</a>. </p>
		<p>Thank you for visiting the Website.</p>
		<h2>CANCELLATION POLICY:</h2>
		<p>BOOKING AND CANCELLATION POLICY</p>
		<p>All the terms and conditions concerning booking, cancellation and refund shall be regulated as per the policy of respective developer.</p>
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
		<h2>Preamble</h2>
		<p>Amura Marketing Technologies Pvt. Ltd., and its affiliated entities around the world (collectively “Amura Marketing Technologies”, “we”, or “us”), is committed to protecting the privacy of your personal information. This Privacy Policy details certain policies implemented throughout our company governing Amura Marketing Technologies’s use of personal information about: visitors to our Internet website (the “Site”) located at the URL: https://www.amuratech.com/ and employees of our clients who use our services and/or products (collectively, services and products are: “Service” or “Services”). Where the Privacy Policy differs depending on whether you are using the Site or the Services, those distinctions will be noted in this Privacy Policy.</p>
		<h2>Information Collection Through the Site:</h2>
		<p>You can generally visit the Site without revealing any personal information about yourself. "Personal information" is any information that can be used to identify an individual, and may include name, address, email address, phone number, login information (account number, password), marketing preferences, or social media account information. However, in certain sections of the site we may invite you to contact us for information or questions, inquire about a job or apply for a job, or to obtain content we provide for informational and marketing purposes. In such situations, you may disclose to us your name, phone number, email address, title, company name, and certain employment-related information.</p>
		<p>We may track and store information such as the total number of visitors to our Site, the number of visitors to each page of our Site, your IP address, your browser type, the number of external web site (defined below) pages you have visited, and other browsing or computer data.</p>
		<h2>Through the Services:</h2>
		<p>When our clients use our Services, our clients may provide us with information about you, including personal information such as your name, address, email, phone number and IP address</p>
		<h2>Use of Information</h2>
		<p>We may use your personal information you submit to the Site to:</p>
		<ul>
			<li>contact you to deliver certain information you have requested</li>
		    <li>verify your authority to enter our Site</li>
		    <li>consider your eligibility for employment</li>
		    <li>improve the content and general administration of the Site</li>
		    <li>address any queries or provide necessary information/resources</li>
		    <li>contact you in relation to your registration for an event/webinar</li>
		    <li>contact the users who have provided their information with respect to any service line</li>
		</ul>
		<p>Amura Marketing Technologies uses the information it receives through our clients’ use of the Services to provide our Services to our clients under their direction and instruction.</p>
		<h2>Disclosure and Onward Transfer of Information</h2>
		<p>We will not rent or sell your personal information to any company or organization. We may provide your personal information to our subsidiaries and affiliates. We may provide your personal information to vendors and service agencies that we may engage to assist us in providing our Services to our clients, or to assist us in verifying your eligibility for employment with Amura Marketing Technologies. Such third parties will be restricted from further distributing your personal information and must enter into a written confidentiality agreement with us. We will also disclose your personal information if we are required to do so by law, regulation or other government authority, or otherwise in cooperation with a bona-fide investigation of a governmental or other public authority, including to meet national security or law enforcement requirements, or to protect the safety of visitors to our Site. We may transfer your personal information to a successor entity upon a merger, consolidation or other corporate reorganization in which Amura Marketing Technologies participates or to a purchaser of all or substantially all of Amura Marketing Technologies’s assets to which the Site and/or Services relate.</p>
		<h2>Links to Third Party Sites</h2>
		<p>The Site may provide links to other web sites or resources over which Amura Marketing Technologies does not have control (“External Web Sites”). Such links do not constitute an endorsement by Amura Marketing Technologies of those External Web Sites. You acknowledge that Amura Marketing Technologies is providing these links to you only as a convenience, and further agree that Amura Marketing Technologies is not responsible for the content of such External Web Sites. Your use of External Web Sites is subject to the terms of use and privacy policies located on the External Web Sites.</p>
		<h2>Limiting the Use of Personal Information Collected Through the Site and Services</h2>
		<p>You can limit our use of personal information collected through our Site by following the instructions at the bottom of each email we send you. You can limit our use of personal information that we obtain via our Services by managing your account at the respective client with whom you interact.</p>
		<h2>Reviewing, Correcting and Deleting Personal Information Collected Through the Site</h2>
		<p>Amura Marketing Technologies provides you with the ability to review, correct, and delete your personal information that we have received if it is inaccurate or you wish us to delete it; provided, however, that Amura Marketing Technologies will retain a copy in its files of all personal information, even if corrected, necessary to resolve disputes. Amura Marketing Technologies retains personal information you submit through our Site for up to 4 years in connection with regulatory, tax, insurance or other requirements in the places in which it operates. Amura Marketing Technologies thereafter deletes or anonymizes such information in accordance with applicable laws. You have the right to review or delete the foregoing information, by contacting Amura Marketing Technologies at:</p>
		<h3>General Counsel</h3>
		<p>Amura Marketing Technologies Technologies Ltd.<br>
		Sr.No.132/1, Plot No.14, Deepa Co.Op.Hsg.Society,<br>
		Mangesh Nagar, Baner-Pashan Link Road,<br>
		Pashan, Pune, Maharashtra 411008<br>
		Email: <a href="mailto:legal@amuratech.com">legal@amuratech.com</a></p>
		<h3>Correction</h3>
		<p>If Amura Marketing Technologies has information about you that you believe is inaccurate, you have the right to request correction of your information. Please see the section titled “Reviewing, Correcting and Deleting Personal Information Collected Through the Site” above for more information on correcting, or requesting correction of, your information.</p>
		<h3>Deletion</h3>
		<p>You may request deletion of your personal information at any time. We may retain certain information about you as required by law and for legitimate business purposes permitted by law. Please see the “Reviewing, Correcting and Deleting Personal Information Collected Through the Site” section above for more information regarding Amura Marketing Technologies's retention and deletion practices.</p>
		<h2>Security</h2>
		<p>We employ procedural and technological measures that are reasonably designed to help protect your personally identifiable information from loss, unauthorized access, disclosure, alteration or destruction. Amura Marketing Technologies uses Transport Layer Security, firewalls, password protection and takes other physical and logical security measures and places internal restrictions on who within Amura Marketing Technologies may access your data to help prevent unauthorized access to your personally identifiable information. Our security is annually audited by a third party, under the ISO27001:2013 standard and additionally to comply with the PCI-DSS version 3.2 for specific client Services.</p>
		<p>The safety and security of your information also depends on you. Where we have given you (or where you have chosen) a password for access to certain parts of our Site, you are responsible for keeping that password confidential. We ask you not to share your password with anyone. You also acknowledge that your account is personal to you and agree not to provide any other person with access to this Site or portions of it using your user name, password or other security information. You agree to notify us immediately of any unauthorized access to or use of your user name or password or any other breach of security.</p>
		<p>Unfortunately, the transmission of information via the Internet is not completely secure. Although we do our best to protect your personal information, as described above, we cannot guarantee the security of your personal information transmitted to our Site. Any transmission of personal information is at your own risk. We are not responsible for circumvention of any privacy settings or security measures contained on the Site.</p>
		<h2>Children’s Privacy</h2>
		<p>Amura Marketing Technologies recognizes the privacy interests of children and we encourage parents and guardians to take an active role in their children’s online activities and interests. The Site is not intended for children under the age of 13. Amura Marketing Technologies does not target the Site to children under 13. Amura Marketing Technologies does not knowingly collect personal information from children under the age of 13.</p>
		<p>If we learn that we have collected or received personal information from a child under 13 without verification or parental consent, we will delete that information. If you believe we might have any such information from or about a child under the age of 13, please contact us at:</p>
		<h2>Cookies</h2>
		<p>In order to enhance your experience on our sites, our web pages use "cookies". Cookies are small text files that we place in your computer's browser to store your preferences. Cookies, by themselves, do not tell us your email address or other personal information unless you choose to provide this information to us by, for example, registering at our Site. Once you choose to provide a web page with personal information, this information may be linked to the data stored in the cookie. A cookie is like a unique identity card. It is unique to your computer and can only be read by the server that gave it to you.</p>
		<p>We use cookies to understand site usage and to improve the content and offerings on our Site. For example, we may use cookies to personalize your experience on our web pages (e.g. to recognize you by name when you return to our Site). We also may use cookies to offer you services.</p>
		<p>Cookies save you time as they help us to remember who you are. Cookies help us to be more efficient. We can learn about what content is important to you and what is not. If you are concerned about cookies, you can turn them off in your browser.</p>
		<p>The full details of all the cookies set by www.Amura Marketing Technologies.com are below:</p>
		<p>Google Analytics - The cookies collect information in an anonymous form, but include data such as how you arrived at the Site, how often you've visited, and which pages you looked at. We use the information to compile reports using Google Analytics. To opt out of being tracked by Google Analytics across all Amura Marketing Technologies websites, visit <a href="http://tools.google.com/dlpage/gaoptout" target="_blank">http://tools.google.com/dlpage/gaoptout</a>.</p>
		<p>The following links explain how to block cookies in your browser:</p>
		<p>How to block cookies in Internet Explorer - <a href="http://windows.microsoft.com/en-US/windows-vista/Block-or-allow-cookies" target="_blank">http://windows.microsoft.com/en-US/windows-vista/Block-or-allow-cookies</a></p>
		<p>How to block cookies in Chrome - <a href="https://support.google.com/chrome/bin/answer.py?hl=en&answer=95647&p=cpn_cookies" target="_blank">https://support.google.com/chrome/bin/answer.py?hl=en&answer=95647&p=cpn_cookies</a></p>
		<p>How to block cookies in Firefox - <a href="http://support.mozilla.org/en-US/kb/enable-and-disable-cookies-website-preferences" target="_blank">http://support.mozilla.org/en-US/kb/enable-and-disable-cookies-website-preferences</a></p>
		<p>How to block cookies in Safari - <a href="http://support.apple.com/kb/PH11913" target="_blank">http://support.apple.com/kb/PH11913</a></p>
		<h2>Privacy Policy Updates</h2>
		<p>Due to the Internet’s rapidly evolving nature, Amura Marketing Technologies may need to update this Privacy Policy from time to time. If so, Amura Marketing Technologies will post a notice of the change and the updated Privacy Policy on our site located at https://www.Amuratech.com. We may also send registered visitors of the Site e-mail notifications notifying such visitors of any changes to the Privacy Policy. If any change is unacceptable to you, you have the right to cease using this Site. If you do not cease using this Site, you will be deemed to have accepted Amura Marketing Technologies’s then current Privacy Policy.</p>
		<p>If you have any questions regarding this Privacy Policy please contact us via e-mail at: <a href="mailto:legal@amuratech.com">legal@amuratech.com</a></p>

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

      Template::UITemplate.where(booking_portal_client_id: client_id).count
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
