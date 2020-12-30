class Template::InvoiceTemplate < Template
  field :name, type: String
  field :default, type: Boolean, default: false

  validates :name, presence: true

  def self.seed(client_id)
    Template::InvoiceTemplate.create(booking_portal_client_id: client_id, name: 'Default Invoice template', content: Template::InvoiceTemplate.default_content, default: true)  if Template::InvoiceTemplate.where(booking_portal_client_id: client_id, name: 'Default Invoice template').blank?
  end

  def self.default_content
<<-'TEMPLATE'
    <style type="text/css">
    <!--
    span.cls_002{font-family:"Calibri Bold",serif;font-size:18.2px;color:rgb(31,78,120);font-weight:bold;font-style:normal;text-decoration: none}
    div.cls_002{font-family:"Calibri Bold",serif;font-size:18.2px;color:rgb(31,78,120);font-weight:bold;font-style:normal;text-decoration: none}
    span.cls_003{font-family:"Calibri Bold",serif;font-size:32.9px;color:rgb(46,117,181);font-weight:bold;font-style:normal;text-decoration: none}
    div.cls_003{font-family:"Calibri Bold",serif;font-size:32.9px;color:rgb(46,117,181);font-weight:bold;font-style:normal;text-decoration: none}
    span.cls_004{font-family:"Calibri Bold",serif;font-size:10.1px;color:rgb(0,0,0);font-weight:bold;font-style:normal;text-decoration: none}
    div.cls_004{font-family:"Calibri Bold",serif;font-size:10.1px;color:rgb(0,0,0);font-weight:bold;font-style:normal;text-decoration: none}
    span.cls_005{font-family:"Calibri Bold",serif;font-size:9px;color:rgb(255,255,255);font-weight:bold;font-style:normal;text-decoration: none}
    div.cls_005{font-family:"Calibri Bold",serif;font-size:10.1px;color:rgb(255,255,255);font-weight:bold;font-style:normal;text-decoration: none}
    span.cls_006{font-family:"Calibri",serif;font-size:9.2px;color:rgb(0,0,0);font-weight:normal;font-style:normal;text-decoration: none}
    div.cls_006{font-family:"Calibri",serif;font-size:9.2px;color:rgb(0,0,0);font-weight:normal;font-style:normal;text-decoration: none}
    span.cls_007{font-family:"Calibri Bold Italic",serif;font-size:11.0px;color:rgb(46,117,181);font-weight:bold;font-style:italic;text-decoration: none}
    div.cls_007{font-family:"Calibri Bold Italic",serif;font-size:11.0px;color:rgb(46,117,181);font-weight:bold;font-style:italic;text-decoration: none}
    span.cls_008{font-family:"Calibri",serif;font-size:11.0px;color:rgb(0,0,0);font-weight:normal;font-style:normal;text-decoration: none}
    div.cls_008{font-family:"Calibri",serif;font-size:11.0px;color:rgb(0,0,0);font-weight:normal;font-style:normal;text-decoration: none}
    span.cls_009{font-family:"Calibri Bold",serif;font-size:12.8px;color:rgb(31,78,120);font-weight:bold;font-style:normal;text-decoration: none}
    div.cls_009{font-family:"Calibri Bold",serif;font-size:12.8px;color:rgb(31,78,120);font-weight:bold;font-style:normal;text-decoration: none}
    span.cls_010{font-family:"Calibri Bold",serif;font-size:12.8px;color:rgb(0,0,0);font-weight:bold;font-style:normal;text-decoration: none}
    div.cls_010{font-family:"Calibri Bold",serif;font-size:12.8px;color:rgb(0,0,0);font-weight:bold;font-style:normal;text-decoration: none}
    span.cls_011{font-family:"Calibri Bold",serif;font-size:9.2px;color:rgb(0,0,0);font-weight:bold;font-style:normal;text-decoration: none}
    div.cls_011{font-family:"Calibri Bold",serif;font-size:9.2px;color:rgb(0,0,0);font-weight:bold;font-style:normal;text-decoration: none}
    -->
    </style>

    <div style="position:absolute;left:50%;margin-left:-297px;top:0px;width:595px;height:841px;border-style:outset;overflow:hidden">
    <div style="position:absolute;left:0px;top:0px">
      <%= image_tag('invoice-template-bg.jpg', width: 595, height: 841) %>
      <% cp = ChannelPartner.where(associated_user_id: @invoice.manager_id).first %>
      <% addr = cp.address.to_sentence %>
      <% client = @invoice.project.booking_portal_client %>
      <% ladder = @invoice.incentive_scheme.ladders.where(stage: @invoice.ladder_stage).first %>
      <% adj = ladder.try(:payment_adjustment) %>
      <% deduction = @invoice.incentive_deduction.try(:approved?) ? @invoice.incentive_deduction : nil %>
      <% subtotal = deduction ? (@invoice.amount-deduction.amount) : @invoice.amount %>
      <div style="position:absolute;left:56.95px;top:70.43px" class="cls_002"><span class="cls_002"><%= cp.company_name %></span></div>
      <div style="position:absolute;left:55.95px;top:104.71px" class="cls_004"><span class="cls_004"><%= addr.split(',')[0] %></span></div>
    <div style="position:absolute;left:55.95px;top:121.78px" class="cls_004"><span class="cls_004"><%= addr.split(',')[1..-1].join(',') %></span></div>
    <div style="position:absolute;left:55.95px;top:138.86px" class="cls_004"><span class="cls_004">Phone: <%= @invoice.manager.phone %></span></div>
    <div style="position:absolute;left:420.73px;top:60.38px" class="cls_003"><span class="cls_003">INVOICE</span></div>
    <div style="position:absolute;left:345px;top:138.41px" class="cls_005"><span class="cls_005">INVOICE #</span></div>
    <div style="position:absolute;left:335px;top:155.49px" class="cls_004"><span class="cls_004"><%= @invoice.number %></span></div>
    <div style="position:absolute;left:479.57px;top:138.86px" class="cls_005"><span class="cls_005">DATE</span></div>
    <div style="position:absolute;left:468.41px;top:155.93px" class="cls_004"><span class="cls_004"><%= @invoice.raised_date.strftime('%d/%m/%Y') %></span></div>
    <div style="position:absolute;left:345px;top:185.95px" class="cls_005"><span class="cls_005">RERA Number</span></div>
    <div style="position:absolute;left:335px;top:201.58px" class="cls_004"><span class="cls_004"><%= cp.rera_id %></span></div>
    <div style="position:absolute;left:450px;top:186.40px" class="cls_005"><span class="cls_005">GSTIN No</span></div>
    <div style="position:absolute;left:450px;top:202.02px" class="cls_004"><span class="cls_004"><%= cp.gstin_number %></span></div>
    <div style="position:absolute;left:64.65px;top:185.95px" class="cls_005"><span class="cls_005">BILL TO</span></div>
    <div style="position:absolute;left:55.84px;top:202.58px" class="cls_006"><span class="cls_006"><%= client.name %></span></div>
    <div style="position:absolute;left:55.84px;top:216.31px" class="cls_006"><span class="cls_006"><%= client.registration_name %></span></div>
    <div style="position:absolute;left:55.84px;top:230.04px" class="cls_006"><span class="cls_006"><%= client.address.to_sentence.split(',')[0] %></span></div>
    <div style="position:absolute;left:55.84px;top:243.76px" class="cls_006"><span class="cls_006"><%= client.address.to_sentence.split(',')[1..-1].join(',') %></span></div>
    <div style="position:absolute;left:55.84px;top:257.49px" class="cls_006"><span class="cls_006"><%= client.helpdesk_number %></span></div>
    <div style="position:absolute;left:55.84px;top:271.25px" class="cls_006"><span class="cls_006"><%= client.helpdesk_email %></span></div>
    <div style="position:absolute;left:64.65px;top:299.48px" class="cls_005"><span class="cls_005">DESCRIPTION</span></div>
    <div style="position:absolute;left:333px;top:299.48px" class="cls_005"><span class="cls_005">LADDER</span></div>
    <div style="position:absolute;left:385px;top:299.48px" class="cls_005"><span class="cls_005">OFFER</span></div>
    <div style="position:absolute;left:460px;top:299.48px" class="cls_005"><span class="cls_005">AMOUNT</span></div>
    <div style="position:absolute;left:55.84px;top:317.67px" class="cls_006"><span class="cls_006">
        Incentive for Booking: <%= @invoice.booking_detail.name %>
      </span></div>
    <div style="position:absolute;left:55.84px;top:335.42px" class="cls_006"><span class="cls_006">
        Project: <%= @invoice.project_name %>
      </span></div>
    <div style="position:absolute;left:55.84px;top:353.16px" class="cls_006"><span class="cls_006">
        Under Scheme: <%= @invoice.incentive_scheme.name %>
      </span></div>
      <div style="position:absolute;left:350.31px;top:317.67px" class="cls_006"><span class="cls_006"><%= @invoice.ladder_stage %></span></div>
      <% if adj.present? %>
        <% if adj.absolute_value.blank? && adj.formula.present? %>
          <% formula = formula_to_human(adj.formula) %>
          <div style="position:absolute;left:380px;top:317.67px" class="cls_006"><span class="cls_006"><%= "#{formula.split('of')[0]} of".html_safe %></span></div>
          <div style="position:absolute;left:375px;top:335.42px" class="cls_006"><span class="cls_006"><%= formula.split('of')[1] %></span></div>
        <% else %>
          <div style="position:absolute;left:395px;top:317.67px" class="cls_006"><span class="cls_006"><%= number_to_indian_currency(adj.absolute_value) %></span></div>
        <% end %>
      <% else %>
        <div style="position:absolute;left:410.91px;top:317.67px" class="cls_006"><span class="cls_006"><%= number_to_indian_currency(@invoice.amount) %></span></div>
      <% end %>
    <div style="position:absolute;left:460px;top:317.67px" class="cls_006"><span class="cls_006"><%= number_to_indian_currency(@invoice.amount) %></span></div>
    <% if deduction %>
      <div style="position:absolute;left:55.84px;top:370.91px" class="cls_006"><span class="cls_006"><%= t('mongoid.attributes.incentive_deduction.number') + deduction.number %></span></div>
      <div style="position:absolute;left:350.31px;top:370.91px" class="cls_006"><span class="cls_006"></span></div>
      <div style="position:absolute;left:415.60px;top:370.91px" class="cls_006"><span class="cls_006"></span></div>
      <div style="position:absolute;left:460px;top:370.91px" class="cls_006"><span class="cls_006"><%= number_to_indian_currency(deduction.amount) %></span></div>
    <% else %>
      <div style="position:absolute;left:522.87px;top:370.91px" class="cls_006"><span class="cls_006">-</span></div>
    <% end %>
    <div style="position:absolute;left:522.87px;top:388.65px" class="cls_006"><span class="cls_006">-</span></div>
    <div style="position:absolute;left:522.87px;top:406.40px" class="cls_006"><span class="cls_006">-</span></div>
    <div style="position:absolute;left:522.87px;top:424.14px" class="cls_006"><span class="cls_006">-</span></div>
    <div style="position:absolute;left:522.87px;top:441.90px" class="cls_006"><span class="cls_006">-</span></div>
    <div style="position:absolute;left:522.87px;top:459.65px" class="cls_006"><span class="cls_006">-</span></div>
    <div style="position:absolute;left:522.87px;top:477.39px" class="cls_006"><span class="cls_006">-</span></div>
    <div style="position:absolute;left:522.87px;top:495.14px" class="cls_006"><span class="cls_006">-</span></div>
    <div style="position:absolute;left:522.87px;top:512.88px" class="cls_006"><span class="cls_006">-</span></div>
    <div style="position:absolute;left:522.87px;top:530.63px" class="cls_006"><span class="cls_006">-</span></div>
    <div style="position:absolute;left:522.87px;top:548.37px" class="cls_006"><span class="cls_006">-</span></div>
    <div style="position:absolute;left:522.87px;top:566.12px" class="cls_006"><span class="cls_006">-</span></div>
    <div style="position:absolute;left:128.06px;top:582.30px" class="cls_007"><span class="cls_007">Thank you for your business!</span></div>
    <div style="position:absolute;left:344.39px;top:582.30px" class="cls_008"><span class="cls_008">SUBTOTAL</span></div>
    <div style="position:absolute;left:460px;top:582.75px" class="cls_008"><span class="cls_008"><%= number_to_indian_currency(subtotal) %></span></div>
    <div style="position:absolute;left:344.39px;top:600.07px" class="cls_008"><span class="cls_008">ADJUSTMENT*</span></div>
    <div style="position:absolute;left:460px;top:600.52px" class="cls_008"><span class="cls_008"><%= number_to_indian_currency(@invoice.net_amount - subtotal) %></span></div>
    <div style="position:absolute;left:344.39px;top:618.26px" class="cls_008"><span class="cls_008">NET AMOUNT</span></div>
    <div style="position:absolute;left:460px;top:618.26px" class="cls_008"><span class="cls_008"><%= number_to_indian_currency(@invoice.net_amount) %></span></div>
    <div style="position:absolute;left:344.62px;top:634.33px" class="cls_009"><span class="cls_009">TOTAL</span></div>
    <div style="position:absolute;left:460px;top:634.78px" class="cls_010"><span class="cls_010"><%= number_to_indian_currency(@invoice.net_amount) %></span></div>
    <div style="position:absolute;left:55.95px;top:676.85px" class="cls_006"><span class="cls_006">If you have any questions about this invoice, please contact <strong>[<%= client.helpdesk_number %>, <%= client.helpdesk_email %>]</strong></span></div>
    <div style="position:absolute;left:55.95px;top:688.68px" class="cls_006"><span class="cls_006">* Adjustments made by Billing Team before approval.</span></div>
TEMPLATE
  end
end
