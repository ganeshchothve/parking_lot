# Template::BookingDetailFormTemplate.seed Client.last.id
class Template::BookingDetailFormTemplate < Template

  field :name, type: String

  def self.seed(project_id, client_id)
    Template::BookingDetailFormTemplate.create(booking_portal_client_id: client_id, project_id: project_id, name: 'booking_detail_form_html', content: Template::BookingDetailFormTemplate.html_content)  if Template::BookingDetailFormTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: 'booking_detail_form_html').blank?
    Template::BookingDetailFormTemplate.create(booking_portal_client_id: client_id, project_id: project_id, name: 'booking_detail_form_pdf', content: Template::BookingDetailFormTemplate.pdf_content)  if Template::BookingDetailFormTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: 'booking_detail_form_pdf').blank?
  end

  def self.html_content
    "<div class='container pt-3 bg-white'>
    <div class='row' align='center'>
      <div class='col-sm' align='center'>
        <img src='<%= @booking_detail.project.logo&.url || current_client&.logo&.url %>' class='img-responsive'>
      </div>
    </div>
    <div class='row' align='center'>
      <div class='col-sm' align='center'>
        <h4><%= @booking_detail.project_name %></h4>
      </div>
    </div>
    <div class='row' align='center'>
      <div class='col-sm' align='center'>
        <h3>Rera Number: <%= @booking_detail.project.rera_registration_no %></h3>
      </div>
    </div>
    <div class='row'>
      <div class='col-sm' align='left'>
        <p>Date: <%= @booking_detail.project_unit.blocked_on.try(:strftime, '%d/%m/%y') %></p>
      </div>
      <div class='col-sm' align='right'>
        <p>Application ID: <%= @booking_detail.receipts.where(:'token_number'.exists => true).first.try(:get_token_number) %> </p>
      </div>
    </div>
    <div class='container border'>
      <div class='row pt-3' align='center'>
        <div class='col-sm' align='center'>
          <h2><strong>Customer Details</strong></h2>
        </div>
      </div>
       <div class='row'>
        <div class='col-sm border pt-3'>
          <strong>First Applicant:</strong>
        </div>
        <div class='col-sm border pt-3'>
          <%= @booking_detail.primary_user_kyc&.first_name || 'First Name' %>
        </div>
        <div class='col-sm border pt-3'>
          <%= @booking_detail.primary_user_kyc&.last_name || 'Last Name' %>
        </div>
      </div>
      <div class='row'>
        <div class='col-sm border pt-3'>
          DoB: <%= @booking_detail.primary_user_kyc&.dob %>
        </div>
        <div class='col-sm border pt-3'>
          PAN Number: <%= @booking_detail.primary_user_kyc&.pan_number %>
        </div>
        <div class='col-5 border pt-3'>
          AADHAAR Number:
          <%=
            if @booking_detail.primary_user_kyc.present?;
              if @booking_detail.primary_user_kyc.aadhaar.present?;
                @booking_detail.primary_user_kyc.aadhaar;
              end;
            end;
          %>
        </div>
      </div>
      <div class='row'>
        <div class='col-sm border pt-3'>
          <strong>Second Applicant Name:</strong>
        </div>
        <div class='col-sm border pt-3'>
          <%= @booking_detail.user_kycs&.first&.first_name %>
        </div>
        <div class='col-sm border pt-3'>
        <%= @booking_detail.user_kycs&.first&.last_name %>
        </div>
      </div>
      <div class='row'>
        <div class='col-sm border pt-3'>
          DoB: <%= @booking_detail.user_kycs&.first&.dob %>
        </div>
        <div class='col-sm border pt-3'>
          PAN Number: <%= @booking_detail.user_kycs&.first&.pan_number %>
        </div>
        <div class='col-5 border pt-3'>
          AADHAAR Number:
        </div>
      </div>
    </div>
    </br>
    <div class='container border'>
      <div class='row pt-3' align='center'>
        <div class='col-sm' align='center'>
          <h2><strong>Communication Details</strong></h2>
        </div>
      </div>
      <div class='row'>
        <div class='col-sm border pt-3'>
          <p>Address:&nbsp<%= @booking_detail.primary_user_kyc&.addresses&.first&.to_sentence %></p>
        </div>
      </div>
      <div class='row'>
        <div class='col-sm border pt-3'>
          <p>Mobile No:&nbsp<%= @booking_detail.user.phone %></p>
        </div>
        <div class='col-sm border pt-3'>
          <p>Alternate Mobile No: <%= (@booking_detail.user.user_kycs.to_a - @booking_detail.primary_user_kyc.to_a)[0].try(:phone) %></p>
        </div>
        <div class='col-sm border pt-3'>
          <p><%= I18n.t('global.email_id') %> :&nbsp<%= @booking_detail.user.email %></p>
        </div>
      </div>
    </div>
    </br>
    <div class='container border'>
      <div class='row pt-3' align='center'>
        <div class='col-sm' align='center'>
          <h2><strong>Unit Details</strong></h2>
        </div>
      </div>
      <div class='row'>
        <div class='col-sm border pt-3'>
          <p>Typology</p>
        </div>
        <div class='col-sm border pt-3'>
          <p>Net Area</p>
        </div>
        <div class='col-sm border pt-3'>
          <p>Building Number</p>
        </div>
        <div class='col-sm border pt-3'>
          <p>Floor</p>
        </div>
        <div class='col-sm border pt-3'>
          <p>Unit No.</p>
        </div>
       <div class='col-sm border pt-3'>
          <p>Car Parking</p>
        </div>
      </div>
      <div class='row'>
        <div class='col-sm border pt-3'>
          <p><%= @booking_detail.project_unit.unit_configuration_name %></p>
        </div>
        <div class='col-sm border pt-3'>
          <p><%= @booking_detail.saleable %></p>
        </div>
        <div class='col-sm border pt-3'>
          <p><%= @booking_detail.project_unit.project_tower_name %></p>
        </div>
        <div class='col-sm border pt-3'>
          <p><%= @booking_detail.project_unit.floor %></p>
        </div>
        <div class='col-sm border pt-3'>
          <p><%= @booking_detail.project_unit.name %></p>
        </div>
        <div class='col-sm border pt-3'>
          <p>Parking No.: _______</p>
        </div>
      </div>
    </div>
    <div class='page-break'></div>
    <div class='container border'>
      <div class='row pt-3' align='center'>
        <div class='col-sm' align='center'>
          <h2><strong>Payment Details</strong></h2>
        </div>
      </div>
      <div class='row'>
        <div class='col-sm border pt-3'>
          <p>Token Amount</p>
        </div>
        <div class='col-sm border pt-3'>
          <p><%= number_to_indian_currency(@booking_detail.receipts.where(payment_type: 'token').first&.total_amount) %></p>
        </div>
        <div class='col-6 border pt-3'>
          <p> <%= @booking_detail.receipts.where(payment_type: 'token').first&.status %></p>
        </div>
      </div>
      <% @booking_detail.receipts.ne(payment_type: 'token').where(payment_mode: 'cheque').each do |r| %>
     <div class = 'row'>
     <div class='col-3 border pt-3'>
          <p>Booking Amount</p>
        </div>
         <div class='col-3 border pt-3'>
           <%= number_to_indian_currency(r&.total_amount) %>
       </div>
         <div class='col-sm border pt-3'>
           <%= r&.issued_date&.strftime('%d/%m/%y') %>
       </div>
        <div class='col-sm border pt-3'>
          <%= r&.payment_identifier %>
        </div>
        <div class='col-sm border pt-3'>
           <%= 'Issuing Bank:' + r&.issuing_bank %>
      </div>
    </div>
<% end %>
<% @booking_detail.receipts.ne(payment_type: 'token').where(payment_mode: {'$ne': 'cheque'}).each do |r| %>
    <div class = 'row'>
     <div class='col-3 border pt-3'>
          <p>Booking Amount</p>
        </div>
         <div class='col-3 border pt-3'>
           <%= number_to_indian_currency(r&.total_amount) %>
       </div>
         <div class='col-sm border pt-3'>
           --
       </div>
        <div class='col-sm border pt-3'>
          <%= r&.payment_identifier %>
        </div>
        <div class='col-sm border pt-3'>
           --
      </div>
    </div>
<% end %>
      <div class='row'>
        <div class='col-3 border pt-3'>
          <p><strong>Total Booking Amount</strong></p>
        </div>
        <div class='col-3 border pt-3'>
          <p><strong> <%= number_to_indian_currency(@booking_detail.receipts.where(payment_type: {'$ne': 'stamp_duty'}).sum(:total_amount)) %> </strong></p>
        </div>
      </div>

<% @booking_detail.receipts.where(payment_type: 'stamp_duty', payment_mode: 'cheque').each do |r| %>
     <div class = 'row'>
     <div class='col-3 border pt-3'>
          <p>Stamp Duty & regitration</p>
        </div>
        <div class='col-3 border pt-3'>
           <%= number_to_indian_currency(r.try(:total_amount)) %>
       </div>
         <div class='col-sm border pt-3'>
           <%= r.try(:issued_date).try(:strftime, '%d/%m/%y') %>
       </div>
        <div class='col-sm border pt-3'>
          <%= r.try(:payment_identifier) %>
        </div>
        <div class='col-sm border pt-3'>
           <%= 'Issuing Bank:' + r.try(:issuing_bank) %>
      </div>
    </div>
<% end %>
<% @booking_detail.receipts.where(payment_type: 'stamp_duty', payment_mode: {'$ne': 'cheque'}).each do |r| %>
    <div class = 'row'>
     <div class='col-3 border pt-3'>
          <p>Stamp Duty & regitration</p>
        </div>
         <div class='col-sm border pt-3'>
           <%= number_to_indian_currency(r.try(:total_amount)) %>
       </div>
         <div class='col-sm border pt-3'>
           --
       </div>
        <div class='col-sm border pt-3'>
          <%= r.try(:payment_identifier) %>
        </div>
        <div class='col-sm border pt-3'>
           --
      </div>
    </div>
<% end %>
    </div>
    </br>
<% if @booking_detail.manager && @booking_detail.manager.role?('channel_partner')%>
    <div class='container border'>
      <div class='row pt-3' align='center'>
        <div class='col-sm'>
          <h2><strong>Mode of Booking</strong></h2>
        </div>
      </div>
      <div class='row pt-3'>
        <div class='col-sm border pt-3'>
          CP Name:
        </div>
        <div class='col-sm border pt-3'>
          CP Mobile No:
        </div>
        <div class='col-sm border pt-3'>
          CP RERA ID:
        </div>
      </div>
    </div>
</br>
<%end%>
    <div class='container'>
      <div class='row pt-3'>
        <div class='col-sm'>
          <p>Declaration: The Applicant(s) do hereby declare that the above information provided by me/us in this application is true and correct and that the Applicants have also read and understood the Terms and Conditions attached with this application as well as the draft Agreement for Sale uploaded on the MAHARERA website and I/we shall abide by the same.</p>
          Yours faithfully,</br>
        </div>
      </div>
      <div class='row pt-3'>
        <div class='col-sm pt-3'>
          [Signature]
        </div>
        <div class='col-sm pt-3'>
          [Signature]
        </div>
        <div class='col-sm pt-3'>
          [Signature]
        </div>
      </div>
      <div class='row pt-3'>
        <div class='col-sm'>
          First Applicant
        </div>
        <div class='col-sm'>
          Second Applicant
        </div>
        <div class='col-sm'>
          Sales Rep
        </div>
      </div>
    </div>
    </br>
    <div class='container'>
      <div class='row pt-3'>
        <div class='col-sm' align='center'>
            TERMS AND CONDITIONS
        </div>
      </div>
      <ol>
        <li>
          The Applicants hereby declare and confirm that the Applicants have booked only one Apartment (residential/commercial unit) in entire <%= @booking_detail.project.name %>. The Applicants further declare that spouse and / or minor child / children of the Applicants have not booked / purchased any other Apartment in the said <%= @booking_detail.project.name %>. The Applicants also confirm that the Applicants and/or spouse and/or minor child / children of the Applicants shall not book / purchase any other Apartment in <%= @booking_detail.project.name %>.
        </li>
        <li>
          The Applicants are aware and agreeable that, if my/our application is accepted by you then upon realization of payments  towards the Booking Amount 1, Booking Amount 2 on agreed date, you shall issue me/us an Allotment Letter within 7 days thereof. In case of failure to comply, you may treat this application as automatically cancelled/withdrawn and thereafter, you shall be at liberty to deal with the Apartment and the multi-level covered car parking spaces these as you may deem fit without any recourse to me/us. In such an event all amounts paid by me/us to you shall fully forfeited and I/We will not seek any refund of the same.
        </li>
        <li>
          The Applicant(s) shall be treated as the “Allottee(s)” upon issuance of the Allotment Letter by the Promoter and shall make timely payments towards the Apartment and the multi-level car parking space, if any, in the manner indicated in the payment Plan annexed.
        </li>
        <li>
          The Applicants authorize the Promoter to make the Stamp Duty and Registration payment to the required authorities on his or her behalf.  On the date of the Stamp Duty & Registration cheque issued by the Applicants, or seven days after the issue of the Allotment Letter if it happens to be later, the Promoter will present to his bank  the said cheque issued by the Applicants at the time of this booking.  The Applicants warrant to ensure sufficient funds in the account to ensure the cheque will be cleared.  The Promoter warrants to furnish a receipt of such payment to the Applicants within 3 days of its issue by the Office of Sub-Registrar of Assurances.
        </li>
        <li>
         The Applicants shall attend the office of the sub-Registrar Bhiwandi or to an e-registration kiosk at the Promoter’s site within 30 days from the date of the Allotment Letter for execution and registration of Agreement for Sale on the day, date and time that will be communicated to the Applicants by Promoter. In case of any cancellation on a later date, the Applicants will have to seek refund of such Stamp Duty and Registration charges from the Government Authorities directly.
        </li>
        If for any reason the cheque for Stamp Duty and Registration charges is dishonoured when presented, the Allotment Letter will stand cancelled and the Applicants shall fully forfeit the Token Amount, Booking Amount 1 and Booking Amount 2 paid to the Promoter and no amount will be refunded to the Applicants.
        <li>
        This Application is not transferable, and the Promoter shall have right on the said Apartment till all amounts due by the Applicants are paid.
        </li>
        <li>
          The Applicants hereby agree and authorize <%= @booking_detail.project.developer_name %> and all of its divisions, affiliates, subsidiaries, related parties and other group companies to access their names, addresses, telephone number, e-mail address, birth date and / or anniversary date (collectively “Basic Date/Contact Details”). The Applicants hereby consent to being contacted through calls/ emails/ SMS/ other communication in order to assist with their purchase or keep them informed regarding product details or send them any product or service related communication and offers. The Applicants provide the details herein at their sole discretion and confirm that no <%= @booking_detail.project.developer_name %> Entity shall be held responsible or liable for any claim arising out of accessing or using their basic data / contact details shared by them. They also agree that if at any point of time, they wish to stop receiving such communications from <%= @booking_detail.project.developer_name %>, they will call at designated call center and register my preference.”
        </li>
      </ol>
      <div class='row pt-3'>
        <div class='col-sm'>
         The Applicants have read and understood these Terms and Conditions and shall abide by the same
        </div>
      </div>
      <div class='row pt-3'>
        <div class='col-sm pt-3'>
          [Name]
        </div>
        <div class='col-sm pt-3'>
          [Name]
        </div>
        <div class='col-sm pt-3'>
          [Name]
        </div>
      </div>
      <div class='row pt-3'>
        <div class='col-sm'>
          First Applicant
        </div>
        <div class='col-sm'>
          Second Applicant
        </div>
        <div class='col-sm'>
          Third Applicant
        </div>
      </div>
    </div>
    <div class='page-break'></div>
    <div class='card mt-3 card-body'>
     <%= @booking_detail.project_unit.cost_sheet_template.parsed_content(@booking_detail) %>
   </div>
   <div class='page-break'></div>
   <div class='card mt-3 card-body'>
      <%= @booking_detail.project_unit.payment_schedule_template.parsed_content(@booking_detail) %>
   </div>
    </br>
   <div class ='container'>
    <div class='row'>
      <div class='col-sm' align='right'>
        <p>Date: <%= @booking_detail.project_unit.blocked_on.try(:strftime, '%d/%m/%y') %></p>
      </div>
    </div>
    <div class='row'>
      <div class='col-sm' align='left'>
        <p>Mr./Ms.: <%= @booking_detail.primary_user_kyc.try(:first_name) %> <%= @booking_detail.primary_user_kyc.try(:last_name) %></p>
      </div>
    </div>
   </div>
    </br>
    <div class ='container'>
    <div class='row'>
      <div class='col-1' align='left'>
        <p>Ref.:</p>
      </div>
      <div class='col-sm' align='left'>
        <p>(1) Project - <%= @booking_detail.project.name %> having RERA Registration No. <%= @booking_detail.project.rera_registration_no %>
</br>(2) Your application dated <%= @booking_detail.project_unit.blocked_on.try(:strftime, '%d/%m/%y') %>  for allotment of an apartment in tower <%= @booking_detail.project_unit.project_tower_name %> in <%= @booking_detail.project.name %> situated, lying and being at <%= @booking_detail.project.address&.to_sentence %>
</p>
      </div>
    </div>
   </div>
   </br>
    <div class ='container'>
      <div class='row'>
        <div class='col-sm' align='left'>
          <p>Dear Sir / Madam,</br> We are pleased to confirm allotment of residential Apartment No.<%= @booking_detail.project_unit.name %> of type <%= @booking_detail.project_unit.unit_configuration.try(:name) %> in <%= @booking_detail.project.name %> admeasuring <%= @booking_detail.saleable %> sq. ft. of Carpet area alongwith for exclusive use of the Allottee open balcony of  ______  sq. ft., enclosed balcony of <%= @booking_detail.project_unit.data.where(key: 'enc_balcony_sqft').first.try(:absolute_value) %> sq. ft., Veranda of ______ sq. ft. and exclusive terrace of  ______  sq. ft., on <%= @booking_detail.project_unit.floor %> floor in the _________ Wing of <%= @booking_detail.project_unit.project_tower_name %> building (“the Apartment”) for the consideration of Rs.<%= number_to_indian_currency(@booking_detail.project_unit.agreement_price) %>/-  (Rupees <%= @booking_detail.project_unit.agreement_price.try(:humanize) %> only) including the proportionate price of the common areas and facilities. We are also allotting covered parking space(s) number _______ for the consideration of Parking charges Rs.
<% if @booking_detail.try(:booking_detail_scheme).try(:car_parking).present? %>
 <%= @booking_detail.booking_detail_scheme.payment_adjustments.collect{|pa| pa.try(:absolute_value)}.sum.round %> (Rupees <%= @booking_detail.booking_detail_scheme.payment_adjustments.collect{|pa| pa.try(:absolute_value)}.sum.round.try(:humanize) %> only)<% else %> ______
<% end %>
  on the terms and conditions and Payment Plan as agreed by you in the Application Form. The Total Consideration as mentioned above excludes Goods and Services Tax (“GST”) and Cess at currently prevailing rates in connection with the construction of and carrying out the Project and/or with respect to the said Apartment and/or Agreement for Sale upto the date of handing over the possession of the said Apartment. Note: At the time of AFS we were informed that Total Consideration is inclusive of GST.
</br>You are required to pay the requisite stamp duty and registration charges within 7 (seven) days from the date of this allotment letter and the Agreement for Sale should be executed between us and registered within 30 (thirty) days from the date of this Allotment Letter. </br>
Yours faithfully,</br><strong>For <%= @booking_detail.project.developer_name %>,</strong></br></br></br>_______________</br>Authorized Signature</p>
        </div>
      </div>
    </div>
  </div>"
  end

  def self.pdf_content
"<table style='width:100%'>
  <tr align='center'>
    <td align='center'><%#= wicked_pdf_image_tag @booking_detail.project&.logo&.url || current_client&.logo&.url %></td>
  </tr>
  <tr align='center'>
    <td align='center'><h4><%= @booking_detail.project_name %></h4> </td>
  </tr>
  <tr>
    <td align='center'><h3>Rera Number: <%= @booking_detail.project.rera_registration_no %></h3></td>
  </tr>
  <tr>
    <td><p>Date: <%= @booking_detail.project_unit.blocked_on.try(:strftime, '%d/%m/%y') %></p></td>
    <td><p>Application ID: <%= @booking_detail.receipts.where(:'token_number'.exists => true).first.try(:get_token_number) %> </p></td>
  </tr>
</table>
</br>
</br>
</br>
<table border = '1' style='width:100%'>
  <tr>
    <td align='center'><h2><strong>Customer Details</strong></h2></td>
  </tr>
  <tr>
    <td><strong>First Applicant:</strong></td>
    <td><%= @booking_detail.primary_user_kyc.try(:first_name) || 'First Name' %></td>
    <td><%= @booking_detail.primary_user_kyc.try(:last_name) || 'Last Name' %></td>
  </tr>
  <tr>
    <td>DoB: <%= @booking_detail.primary_user_kyc.try(:dob) %></td>
    <td>PAN Number: <%= @booking_detail.primary_user_kyc.try(:pan_number) %></td>
    <td>AADHAAR Number: <%= if @booking_detail.primary_user_kyc.present?;
    if @booking_detail.primary_user_kyc.aadhaar.present?;
      @booking_detail.primary_user_kyc.aadhaar;
     end;
     end; %></td>
  </tr>
  <tr>
    <td><strong>Second Applicant Name:</strong></td>
    <td><%= @booking_detail.user_kycs.try(:first).try(:first_name) %></td>
    <td><%= @booking_detail.user_kycs.try(:first).try(:last_name) %></td>
  </tr>
  <tr>
    <td>DoB: <%= @booking_detail.user_kycs.try(:first).try(:dob) %></td>
    <td>PAN Number: <%= @booking_detail.user_kycs.try(:first).try(:pan_number) %></td>
    <td>AADHAAR Number: </td>
  </tr>
</table>
</br>
</br>
</br>
<table border = '1' style='width:100%'>
  <tr>
    <td align='center'><h2><strong>Communication Details</strong></h2></td>
  </tr>
  <tr>
    <td><p>Address:&nbsp<%= @booking_detail.primary_user_kyc&.addresses&.first&.to_sentence %></p></td>
  </tr>
  <tr>
    <td><p>Mobile No:&nbsp<%= @booking_detail.user.phone %></p></td>
    <td><p>Alternate Mobile No: <%= (@booking_detail.user.user_kycs.to_a - @booking_detail.primary_user_kyc.to_a)[0].try(:phone) %></p></td>
    <td><p><%= I18n.t('global.email_id') %>:&nbsp<%= @booking_detail.user.email %></p></td>
  </tr>
</table>
</br>
</br>
</br>
<table border = '1' style='width:100%'>
  <tr>
    <td align='center'><h2><strong>Unit Details</strong></h2></td>
  </tr>
  <tr>
    <td><p>Typology</p></td>
    <td><p>Net Area</p></td>
    <td><p>Building Number</p></td>
    <td><p>Floor</p></td>
    <td><p>Unit No.</p></td>
    <td><p>Car Parking</p></td>
  </tr>
    <td><p><%= @booking_detail.project_unit.unit_configuration_name %></p></td>
    <td><p><%= @booking_detail.saleable %></p></td>
    <td><p><%= @booking_detail.project_unit.project_tower_name %></p></td>
    <td><p><%= @booking_detail.project_unit.floor %></p></td>
    <td><p><%= @booking_detail.project_unit.name %></p></td>
    <td><p>Parking No.: _______</p></td>
  <tr>
  </tr>
</table>
</br>
</br>
</br>
<table border = '1' style='width:100%'>
  <tr>
    <td align='center'><h2><strong>Payment Details</strong></h2></td>
  </tr>
  <tr>
    <td><p>Token Amount</p></td>
    <td><p><%= number_to_indian_currency(@booking_detail.receipts.where(payment_type: 'token').first.try(:total_amount)) %></p></td>
    <td><p> <%= @booking_detail.receipts.where(payment_type: 'token').first.try(:status) %></p></td>
  </tr>
  <% @booking_detail.receipts.ne(payment_type: 'token').where(payment_mode: 'cheque').each do |r| %>
    <tr>
      <td><p>Booking Amount</p></td>
      <td><%= number_to_indian_currency(r.try(:total_amount)) %></td>
      <td><%= r.try(:issued_date).try(:strftime, '%d/%m/%y') %></td>
      <td><%= r.try(:payment_identifier) %></td>
      <td><%= 'Issuing Bank:' + r.try(:issuing_bank) %></td>
    </tr>
  <% end %>
  <% @booking_detail.receipts.ne(payment_type: 'token').where(payment_mode: {'$ne': 'cheque'}).each do |r| %>
    <tr>
      <td><p>Booking Amount</p></td>
      <td><%= number_to_indian_currency(r.try(:total_amount)) %></td>
      <td>--</td>
      <td><%= r.try(:payment_identifier) %></td>
      <td>--</td>
    </tr>
  <% end %>
  <tr>
    <td><p><strong>Total Booking Amount</strong></p></td>
    <td><p><strong> <%= number_to_indian_currency(@booking_detail.receipts.where(payment_type: {'$ne': 'stamp_duty'}).sum(:total_amount)) %> </strong></p></td>
  </tr>
  <% @booking_detail.receipts.where(payment_type: 'stamp_duty', payment_mode: 'cheque').each do |r| %>
    <tr>
      <td><p>Stamp Duty & regitration</p></td>
      <td><%= number_to_indian_currency(r.try(:total_amount)) %></td>
      <td><%= r.try(:issued_date).try(:strftime, '%d/%m/%y') %></td>
      <td><%= r.try(:payment_identifier) %></td>
      <td><%= 'Issuing Bank:' + r.try(:issuing_bank) %></td>
    </tr>
  <% end %>
  <% @booking_detail.receipts.where(payment_type: 'stamp_duty', payment_mode: {'$ne': 'cheque'}).each do |r| %>
    <tr>
      <td><p>Stamp Duty & regitration</p></td>
      <td><%= number_to_indian_currency(r.try(:total_amount)) %></td>
      <td>--</td>
      <td><%= r.try(:payment_identifier) %></td>
      <td>--</td>
    </tr>
  <% end %>
</table>
</br>
</br>
</br>
<table border = '1'>
  <% if @booking_detail.manager && @booking_detail.manager.role?('channel_partner')%>
    <tr>
      <td><h2><strong>Mode of Booking</strong></h2></td>
      <td>CP Name:</td>
      <td>CP Mobile No:</td>
      <td>CP RERA ID:</td>
    </tr>
  <% end %>
</table>
<table>
  <tr>
    <td><p>Declaration: The Applicant(s) do hereby declare that the above information provided by me/us in this application is true and correct and that the Applicants have also read and understood the Terms and Conditions attached with this application as well as the draft Agreement for Sale uploaded on the MAHARERA website and I/we shall abide by the same.</p>
    Yours faithfully,</br></td>
  </tr>
</table>
<table>
  <tr>
    <td style='width:30%'>[Signature]</td>
    <td style='width:30%'>[Signature]</td>
    <td style='width:30%'>[Signature]</td>
  </tr>
  <tr>
    <td style='width:30%'>First Applicant</td>
    <td style='width:30%'>Second Applicant</td>
    <td style='width:30%'>Sales Rep</td>
  </tr>
</table>
</br>
<table>
  <tr align='center'>
    <td align='center'>TERMS AND CONDITIONS</td>
  </tr>
  <tr align='center'>
    <td>
      <ol>
        <li>
          The Applicants hereby declare and confirm that the Applicants have booked only one Apartment (residential/commercial unit) in entire <%= @booking_detail.project.name %>. The Applicants further declare that spouse and / or minor child / children of the Applicants have not booked / purchased any other Apartment in the said <%= @booking_detail.project.name %>. The Applicants also confirm that the Applicants and/or spouse and/or minor child / children of the Applicants shall not book / purchase any other Apartment in <%= @booking_detail.project.name %>.
        </li>
        <li>
          The Applicants are aware and agreeable that, if my/our application is accepted by you then upon realization of payments  towards the Booking Amount 1, Booking Amount 2 on agreed date, you shall issue me/us an Allotment Letter within 7 days thereof. In case of failure to comply, you may treat this application as automatically cancelled/withdrawn and thereafter, you shall be at liberty to deal with the Apartment and the multi-level covered car parking spaces these as you may deem fit without any recourse to me/us. In such an event all amounts paid by me/us to you shall fully forfeited and I/We will not seek any refund of the same.
        </li>
        <li>
          The Applicant(s) shall be treated as the “Allottee(s)” upon issuance of the Allotment Letter by the Promoter and shall make timely payments towards the Apartment and the multi-level car parking space, if any, in the manner indicated in the payment Plan annexed.
        </li>
        <li>
          The Applicants authorize the Promoter to make the Stamp Duty and Registration payment to the required authorities on his or her behalf.  On the date of the Stamp Duty & Registration cheque issued by the Applicants, or seven days after the issue of the Allotment Letter if it happens to be later, the Promoter will present to his bank  the said cheque issued by the Applicants at the time of this booking.  The Applicants warrant to ensure sufficient funds in the account to ensure the cheque will be cleared.  The Promoter warrants to furnish a receipt of such payment to the Applicants within 3 days of its issue by the Office of Sub-Registrar of Assurances.
        </li>
        <li>
         The Applicants shall attend the office of the sub-Registrar Bhiwandi or to an e-registration kiosk at the Promoter’s site within 30 days from the date of the Allotment Letter for execution and registration of Agreement for Sale on the day, date and time that will be communicated to the Applicants by Promoter. In case of any cancellation on a later date, the Applicants will have to seek refund of such Stamp Duty and Registration charges from the Government Authorities directly.
        </li>
        If for any reason the cheque for Stamp Duty and Registration charges is dishonoured when presented, the Allotment Letter will stand cancelled and the Applicants shall fully forfeit the Token Amount, Booking Amount 1 and Booking Amount 2 paid to the Promoter and no amount will be refunded to the Applicants.
        <li>
        This Application is not transferable, and the Promoter shall have right on the said Apartment till all amounts due by the Applicants are paid.
        </li>
        <li>
          The Applicants hereby agree and authorize <%= @booking_detail.project.developer_name %> and all of its divisions, affiliates, subsidiaries, related parties and other group companies to access their names, addresses, telephone number, e-mail address, birth date and / or anniversary date (collectively “Basic Date/Contact Details”). The Applicants hereby consent to being contacted through calls/ emails/ SMS/ other communication in order to assist with their purchase or keep them informed regarding product details or send them any product or service related communication and offers. The Applicants provide the details herein at their sole discretion and confirm that no <%= @booking_detail.project.developer_name %> Entity shall be held responsible or liable for any claim arising out of accessing or using their basic data / contact details shared by them. They also agree that if at any point of time, they wish to stop receiving such communications from <%= @booking_detail.project.developer_name %>, they will call at designated call center and register my preference.”
        </li>
      </ol>
    </td>
  </tr>
</table>
<table>
  <tr>
    <td>The Applicants have read and understood these Terms and Conditions and shall abide by the same</td>
  </tr>
</table>
<table>
  <tr>
    <td style='width:30%'>[Name]</td>
    <td style='width:30%'>[Name]</td>
    <td style='width:30%'>[Name]</td>
  </tr>
  <tr>
    <td style='width:30%'>First Applicant</td>
    <td style='width:30%'>Second Applicant</td>
    <td style='width:30%'>Third Applicant</td>
  </tr>
</table>
<table>
  <tr>
    <td><%= @booking_detail.project_unit.cost_sheet_template.parsed_content(@booking_detail) %></td>
  </tr>
  <tr>
    <td><%= @booking_detail.project_unit.payment_schedule_template.parsed_content(@booking_detail) %></td>
  </tr>
</table>
</br>
</br>
<table>
  <tr>
    <td><p>Date: <%= @booking_detail.project_unit.blocked_on.try(:strftime, '%d/%m/%y') %></p></td>
  </tr>
  <tr>
    <td><p>Mr./Ms.: <%= @booking_detail.primary_user_kyc.try(:first_name) %> <%= @booking_detail.primary_user_kyc.try(:last_name) %></p></td>
  </tr>
  <tr>
    <td><p>Ref.:</p></td>
  </tr>
  <tr>
    <td>p>(1) Project - <%= @booking_detail.project.name %> having RERA Registration No. <%= @booking_detail.project_unit.project.rera_registration_no %>
    </br>(2) Your application dated <%= @booking_detail.project_unit.blocked_on.try(:strftime, '%d/%m/%y') %>  for allotment of an apartment in tower <%= @booking_detail.project_unit.project_tower_name %> in <%= @booking_detail.project.name %> situated, lying and being at <%= @booking_detail.project.address&.to_sentence %>
    </p></td>
  </tr>
  <tr>
    <td>
        <p>Dear Sir / Madam,</br> We are pleased to confirm allotment of residential Apartment No.<%= @booking_detail.project_unit.name %> of type <%= @booking_detail.project_unit.unit_configuration.try(:name) %> in <%= @booking_detail.project.name %> admeasuring <%= @booking_detail.saleable %> sq. ft. of Carpet area alongwith for exclusive use of the Allottee open balcony of  ______  sq. ft., enclosed balcony of <%= @booking_detail.project_unit.data.where(key: 'enc_balcony_sqft').first.try(:absolute_value) %> sq. ft., Veranda of ______ sq. ft. and exclusive terrace of  ______  sq. ft., on <%= @booking_detail.project_unit.floor %> floor in the _________ Wing of <%= @booking_detail.project_unit.project_tower_name %> building (“the Apartment”) for the consideration of Rs.<%= number_to_indian_currency(@booking_detail.project_unit.agreement_price) %>/-  (Rupees <%= @booking_detail.project_unit.agreement_price.try(:humanize) %> only) including the proportionate price of the common areas and facilities. We are also allotting covered parking space(s) number _______ for the consideration of Parking charges Rs.
      <% if @booking_detail.try(:booking_detail_scheme).try(:car_parking).present? %>
       <%= @booking_detail.booking_detail_scheme.payment_adjustments.collect{|pa| pa.try(:absolute_value)}.sum.round %> (Rupees <%= @booking_detail.booking_detail_scheme.payment_adjustments.collect{|pa| pa.try(:absolute_value)}.sum.round.try(:humanize) %> only)<% else %> ______
      <% end %>
        on the terms and conditions and Payment Plan as agreed by you in the Application Form. The Total Consideration as mentioned above excludes Goods and Services Tax (“GST”) and Cess at currently prevailing rates in connection with the construction of and carrying out the Project and/or with respect to the said Apartment and/or Agreement for Sale upto the date of handing over the possession of the said Apartment. Note: At the time of AFS we were informed that Total Consideration is inclusive of GST.
      </br>You are required to pay the requisite stamp duty and registration charges within 7 (seven) days from the date of this allotment letter and the Agreement for Sale should be executed between us and registered within 30 (thirty) days from the date of this Allotment Letter. </br>
      Yours faithfully,</br><strong>For <%= @booking_detail.project.developer_name %>,</strong></br></br></br>_______________</br>Authorized Signature</p>
    </td>
  </tr>
</table>
    "
  end
end
