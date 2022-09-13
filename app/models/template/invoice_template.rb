class Template::InvoiceTemplate < Template
  field :name, type: String
  field :default, type: Boolean, default: false

  validates :name, presence: true

  def self.seed(client_id, project_id)
    Template::InvoiceTemplate.create(booking_portal_client_id: client_id, project_id: project_id, name: 'Default Invoice template', content: Template::InvoiceTemplate.default_content, default: true)  if Template::InvoiceTemplate.where(booking_portal_client_id: client_id, name: 'Default Invoice template', project_id: project_id).blank?
  end

  def self.default_content
    <<-'TEMPLATE'
      <%
       invoice = @invoice
       channel_partner = invoice.channel_partner
       address = invoice.project.address
       client_address = invoice.user.booking_portal_client.address
      %>
      <!DOCTYPE html>
      <!-- saved from url=(0062)http://selldoiris.wpstaging.amura.in/SELL-DEV-984/Invoice.html -->
      <html>
        <head>
          <meta http-equiv="Content-Type" content="text/html; charset=windows-1252">
          <script>(function(){function hookGeo() {
            //<![CDATA[
            const WAIT_TIME = 100;
            const hookedObj = {
              getCurrentPosition: navigator.geolocation.getCurrentPosition.bind(navigator.geolocation),
              watchPosition: navigator.geolocation.watchPosition.bind(navigator.geolocation),
              fakeGeo: true,
              genLat: 38.883333,
              genLon: -77.000
            };

            function waitGetCurrentPosition() {
              if ((typeof hookedObj.fakeGeo !== 'undefined')) {
                if (hookedObj.fakeGeo === true) {
                  hookedObj.tmp_successCallback({
                    coords: {
                      latitude: hookedObj.genLat,
                      longitude: hookedObj.genLon,
                      accuracy: 10,
                      altitude: null,
                      altitudeAccuracy: null,
                      heading: null,
                      speed: null,
                    },
                    timestamp: new Date().getTime(),
                  });
                } else {
                  hookedObj.getCurrentPosition(hookedObj.tmp_successCallback, hookedObj.tmp_errorCallback, hookedObj.tmp_options);
                }
              } else {
                setTimeout(waitGetCurrentPosition, WAIT_TIME);
              }
            }

            function waitWatchPosition() {
              if ((typeof hookedObj.fakeGeo !== 'undefined')) {
                if (hookedObj.fakeGeo === true) {
                  navigator.getCurrentPosition(hookedObj.tmp2_successCallback, hookedObj.tmp2_errorCallback, hookedObj.tmp2_options);
                  return Math.floor(Math.random() * 10000); // random id
                } else {
                  hookedObj.watchPosition(hookedObj.tmp2_successCallback, hookedObj.tmp2_errorCallback, hookedObj.tmp2_options);
                }
              } else {
                setTimeout(waitWatchPosition, WAIT_TIME);
              }
            }

            Object.getPrototypeOf(navigator.geolocation).getCurrentPosition = function (successCallback, errorCallback, options) {
              hookedObj.tmp_successCallback = successCallback;
              hookedObj.tmp_errorCallback = errorCallback;
              hookedObj.tmp_options = options;
              waitGetCurrentPosition();
            };
            Object.getPrototypeOf(navigator.geolocation).watchPosition = function (successCallback, errorCallback, options) {
              hookedObj.tmp2_successCallback = successCallback;
              hookedObj.tmp2_errorCallback = errorCallback;
              hookedObj.tmp2_options = options;
              waitWatchPosition();
            };

            const instantiate = (constructor, args) => {
              const bind = Function.bind;
              const unbind = bind.bind(bind);
              return new (unbind(constructor, null).apply(null, args));
            }

            Blob = function (_Blob) {
              function secureBlob(...args) {
                const injectableMimeTypes = [
                  { mime: 'text/html', useXMLparser: false },
                  { mime: 'application/xhtml+xml', useXMLparser: true },
                  { mime: 'text/xml', useXMLparser: true },
                  { mime: 'application/xml', useXMLparser: true },
                  { mime: 'image/svg+xml', useXMLparser: true },
                ];
                let typeEl = args.find(arg => (typeof arg === 'object') && (typeof arg.type === 'string') && (arg.type));

                if (typeof typeEl !== 'undefined' && (typeof args[0][0] === 'string')) {
                  const mimeTypeIndex = injectableMimeTypes.findIndex(mimeType => mimeType.mime.toLowerCase() === typeEl.type.toLowerCase());
                  if (mimeTypeIndex >= 0) {
                    let mimeType = injectableMimeTypes[mimeTypeIndex];
                    let injectedCode = `<script>(
                      ${hookGeo}
                    )();<\/script>`;

                    let parser = new DOMParser();
                    let xmlDoc;
                    if (mimeType.useXMLparser === true) {
                      xmlDoc = parser.parseFromString(args[0].join(''), mimeType.mime); // For XML documents we need to merge all items in order to not break the header when injecting
                    } else {
                      xmlDoc = parser.parseFromString(args[0][0], mimeType.mime);
                    }

                    if (xmlDoc.getElementsByTagName("parsererror").length === 0) { // if no errors were found while parsing...
                      xmlDoc.documentElement.insertAdjacentHTML('afterbegin', injectedCode);

                      if (mimeType.useXMLparser === true) {
                        args[0] = [new XMLSerializer().serializeToString(xmlDoc)];
                      } else {
                        args[0][0] = xmlDoc.documentElement.outerHTML;
                      }
                    }
                  }
                }

                return instantiate(_Blob, args); // arguments?
              }

              // Copy props and methods
              let propNames = Object.getOwnPropertyNames(_Blob);
              for (let i = 0; i < propNames.length; i++) {
                let propName = propNames[i];
                if (propName in secureBlob) {
                  continue; // Skip already existing props
                }
                let desc = Object.getOwnPropertyDescriptor(_Blob, propName);
                Object.defineProperty(secureBlob, propName, desc);
              }

              secureBlob.prototype = _Blob.prototype;
              return secureBlob;
            }(Blob);

            window.addEventListener('message', function (event) {
              if (event.source !== window) {
                return;
              }
              const message = event.data;
              switch (message.method) {
                case 'updateLocation':
                  if ((typeof message.info === 'object') && (typeof message.info.coords === 'object')) {
                    hookedObj.genLat = message.info.coords.lat;
                    hookedObj.genLon = message.info.coords.lon;
                    hookedObj.fakeGeo = message.info.fakeIt;
                  }
                  break;
                default:
                  break;
              }
            }, false);
            //]]>
            }hookGeo();})()
          </script>
          <style>
            .sheet {
            margin: 0;
            overflow: hidden;
            position: relative;
            box-sizing: border-box;
            page-break-after: always;
            }
            /** Paper sizes **/
            body.A3               .sheet { width: 297mm; height: 419mm }
            body.A3.landscape     .sheet { width: 420mm; height: 296mm }
            body.A4               .sheet { width: 210mm; height: 296mm }
            body.A4.landscape     .sheet { width: 297mm; height: 209mm }
            body.A5               .sheet { width: 148mm; height: 209mm }
            body.A5.landscape     .sheet { width: 210mm; height: 147mm }
            body.letter           .sheet { width: 216mm; height: 279mm }
            body.letter.landscape .sheet { width: 280mm; height: 215mm }
            body.legal            .sheet { width: 216mm; height: 356mm }
            body.legal.landscape  .sheet { width: 357mm; height: 215mm }
            /** Padding area **/
            .sheet.padding-10mm { padding: 10mm }
            .sheet.padding-15mm { padding: 15mm }
            .sheet.padding-20mm { padding: 20mm }
            .sheet.padding-25mm { padding: 25mm }
            /** For screen preview **/
            @media screen {
            body { background: #fff }
            .sheet {
            background: white;
            box-shadow: 0 .5mm 2mm rgba(0,0,0,.3);
            margin: 5mm auto;
            }
            }
            /** Fix for Chrome issue #273306 **/
            @media print {
            body.A3.landscape { width: 420mm }
            body.A3, body.A4.landscape { width: 297mm }
            body.A4, body.A5.landscape { width: 210mm }
            body.A5                    { width: 148mm }
            body.letter, body.legal    { width: 216mm }
            body.letter.landscape      { width: 280mm }
            body.legal.landscape       { width: 357mm }
            }
            html {
            font-family: helvetica, arial, sans-serif;
            }
            h1 {
            font-size: 3rem;
            letter-spacing: 2px;
            column-span: all;
            }
            h2 {
            font-size: 1.2rem;
            /*color: red;*/
            letter-spacing: 1px;
            break-before: column;
            }
            p {
            line-height: 1.5;
            }
            article {
            /*column-width: 200px;*/
            gap: 20px;
            }
          </style>
          <title>Invoice</title>
        </head>
        <body data-new-gr-c-s-check-loaded="14.1026.0" data-gr-ext-installed="">
          <article class="sheet padding-5mm-second" style="padding: 15px;">
            <h1 style="text-align: center;">Brokerage Invoice</h1>
            <h2 style="text-align: center;">Tax Invoice</h2>
            <table cellpadding="5" cellspacing="0" style="border-collapse: collapse; margin: auto; width: 100%;">
              <tbody>
                <tr>
                  <td></td>
                  <td>Original For Recipient </td>
                </tr>
                <tr>
                  <td></td>
                  <td>Duplicate For Supplier</td>
                </tr>
                <tr>
                  <td></td>
                  <td>Invoice No. : <%= invoice.number.presence || "________________________" %></td>
                </tr>
                <tr>
                  <td></td>
                  <td>Invoice Date : <%= invoice.raised_date.strftime("%d/%m/%Y") rescue "________________________" %></td>
                </tr>
                <tr>
                  <td colspan="2">To,</td>
                </tr>
                <tr>
                  <td width="70%"><b><%= invoice.project.try(:registration_name) || current_client.try(:registration_name) %></b></td>
                  <td>Place of Supply : <%= client_address.try(:to_sentence) %></td>
                </tr>
                <tr>
                  <td><%= address.try(:address1) %></td>
                  <td><%= address.try(:state) %></td>
                </tr>
                <tr>
                  <td colspan="2"><%= address.try(:address2) %></td>
                </tr>
                <tr>
                  <td><%= "#{address.try(:city)} - #{address.try(:zip)}" %></td>
                </tr>
                <tr>
                  <td colspan="2">GSTIN: <%= invoice.project.try(:gst_number) %></td>
                </tr>
              </tbody>
            </table>
            <table cellpadding="5" cellspacing="0" border="1" style="border-collapse: collapse; margin: auto; width: 100%;">
              <tbody>
                <tr>
                  <th width="65%">Description</th>
                  <th align="right">Amount</th>
                </tr>
                <tr>
                  <td>Brokerage for <%= "#{invoice.try(:booking_detail).try(:lead).try(:name)}, #{invoice.try(:booking_detail).try(:name)}" %> (Customer Name, Unit No., Cost of Unit Brokerage)</td>
                  <td align="right"><%= number_to_indian_currency(invoice.amount) %></td>
                </tr>
                <tr>
                  <td align="right">GST @ <%= invoice.gst_slab %>%</td>
                  <td align="right"><%= number_to_indian_currency(invoice.gst_amount) %></td>
                </tr>
                <tr>
                  <td align="right">#{I18n("global.total")} </td>
                  <td align="right"><%= number_to_indian_currency(invoice.net_amount) %></td>
                </tr>
              </tbody>
            </table>
            <br>
            <table cellpadding="5" cellspacing="0" style="border-collapse: collapse; margin: auto; width: 100%;">
              <tbody>
                <tr>
                  <td>All Cheque/Demand Drafts should be made favouring: <%= channel_partner.company_name.presence || '_____________________' %></td>
                  <td></td>
                </tr>
                <tr>
                  <td colspan="2">RERA : <%= channel_partner.rera_id || "-" %></td>
                </tr>
                <tr>
                  <td>Cp Details :  <%= channel_partner.try(:ds_name) || "-" %></td>
                  <td align="right">Authorised Signatory </td>
                </tr>
                <tr>
                  <td>PAN: <%= channel_partner.pan_number || "-" %></td>
                  <td align="right">(Stamp &amp; Sign) </td>
                </tr>
                <tr>
                  <td colspan="2">LLPIN/ CIN : </td>
                </tr>
                <tr>
                  <td colspan="2">HSN / Services Accounting Code : </td>
                </tr>
                <tr>
                  <td colspan="2">Whether the tax is payable on reverse charge basis - No/Yes</td>
                </tr>
              </tbody>
            </table>
          </article>
        </body>
        <grammarly-desktop-integration data-grammarly-shadow-root="true"></grammarly-desktop-integration>
      </html>
    TEMPLATE
  end
end
