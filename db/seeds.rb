# Create user erp model
ErpModel.create(resource_class: 'User', domain: 'https://gerasb-gerasb.cs57.force.com', reference_key_name: 'sfdc_lead_id', url: 'EOIIRISCreateLead/services/apexrest/Integration/IRISLead/', request_type: :json, http_verb: 'post', reference_key_location: '', request_payload: '{api_key: "IRISzpfgh18qq1", last_name: "<%= record.last_name %>", first_name: "<%= record.first_name %>", api_source: "iris", iris_lead_id: "<%= record.id.to_s %>", primary_phone: "<%= record.phone %>", primary_email: "<%= record.email %>", lead_status: "open", medium_name: "web", first_enquiry_received_at: "<%= record.created_at.strftime(\'%Y-%m-%d\') %>", country_code_primary_phone: "+91",  Project_Interested: "demo project", LeadSource: "web", Sub_Source: "website", portal_stage: "Dashboard", portal_cp_id: "<%= record.manager.try(:erp_id) %>" }', is_active: true, action_name: 'create')
# Update user erp model
ErpModel.create(resource_class: 'User', domain: 'https://gerasb-gerasb.cs57.force.com', reference_key_name: 'sfdc_lead_id', url: 'EOIIRISLeadUpdate/services/apexrest/Integration/IRISUpdateLead/', request_type: :json, http_verb: 'post', reference_key_location: '', request_payload: '{ sfdc_lead_id: "<%= record.erp_id %>", iris_lead_id: "<%= record.id.to_s %>", api_key: "IRISzpfgh18qq1", portal_stage: "Dashboard", assign_manager: "<%= record.manager.try(:name) %>", sourcing_manager: "Surabh", attending_manager: "Vishal"}', is_active: true, action_name: 'update')
# Create user kyc erp model
# TODO: birthdate is mandatory in sfdc api - so need to handle it accordingly.
ErpModel.create(resource_class: 'UserKyc', domain: 'https://gerasb-gerasb.cs57.force.com', reference_key_name: 'sfdc_lead_id', url: 'EOIIRISKYCDetails/services/apexrest/Integration/IRISKYCDetails', request_type: :json, http_verb: 'post', reference_key_location: '', request_payload: '{api_key: "IRISzpfgh18qq1", iris_lead_id: "<%= record.user.id.to_s %>", pan_card_number: "<%= record.pan_number %>", api_source: "iris", birthdate: "<%= record.dob %>", nationality: "Indian", house_number: "5", street: "MG Road", city: "Banglore", state: "Karnataka", country: "India", zip: "411048", aadhar_number: "<%= record.aadhaar %>", salutation: "<%= record.salutation %>", company_name: "<%= record.company_name %>", configuration_preference: "<%= record.configurations %>"}', is_active: true, action_name: 'create')
# Create Channel Partner erp model
# TODO: city, country, region & street are mandatory fields in sfdc api - handle it.
ErpModel.create(resource_class: 'ChannelPartner', domain: 'https://gerasb-gerasb.cs57.force.com', reference_key_name: 'sfdc_lead_id', url: 'EOIIRISCP/services/apexrest/Integration/IRIS1CP', request_type: :json, http_verb: 'post', reference_key_location: '', request_payload: '{api_key: "IRISzpfgh18qq1", cp_id: "<%= record.id %>", first_name: "<%= record.first_name %>", last_name: "<%= record.last_name %>", mobile_phone: "<%= record.phone %>", rera_id: "<%= record.rera_id %>", city: "<%= record.address.try(:city) %>", region: "<%= record.address.try(:state) %>", country: "<%= record.address.try(:country) %>", street: "<%= record.address.try(:address2) %>", title: "<%= record.title %>",street2: "",street3: "",house_number: "<%= record.address.try(:address1) %>", district: "Pune", postal_code: "<%= record.address.try(:zip) %>", email: "<%= record.email %>", company_name: "<%= record.company_name %>", pan_no: "<%= record.pan_number %>", gstin_no: "<%= record.gstin_number %>", bank_name: "<%= record.bank_detail.try(:name) %>", bank_beneficiary_account: "<%= record.bank_detail.try(:account_number) %>", bank_account_type: "<%= record.bank_detail.try(:account_type) %>", bank_address: "Baner Road", bank_city: "Pune", bank_postal_code: "423235", bank_region: "MAH", bank_country: "India", bank_ifsc_code: "<%= record.bank_detail.try(:ifsc_code) %>", bank_phone: ""}', is_active: true, action_name: 'create')
# Create Receipt erp model
ErpModel.create(resource_class: 'Receipt', domain: 'https://gerasb-gerasb.cs57.force.com', reference_key_name: 'sfdc_lead_id', url: 'IRISPaymentDetails/services/apexrest/Integration/IRISPaymentDetails', request_type: :json, http_verb: 'post', reference_key_location: '', request_payload: '{api_key: "IRISzpfgh18qq1", receipt_iris_id: "<%= record.id.to_s %>", payment_amount: "<%= record.total_amount %>", iris_lead_id: "<%= record.user.id.to_s %>", mode_of_transfer: "<%= record.payment_mode %>", primary_email: "<%= record.user.email %>", receipt_date: "<%= record.issued_date %>", instrument_no: "pay_A34Wnj2CQ29UUn", instrument_date: "2018-04-24", instrument_received_date: "2018-04-24", bank_name: "<%= record.issuing_bank %>", branch_name: "<%= record.issuing_bank_branch %>", payment_type: "Token", receipt_status: "<%= record.status %>"}', is_active: true, action_name: 'create')
