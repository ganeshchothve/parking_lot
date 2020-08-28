class DocumentSign
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :access_token, type: String
  field :refresh_token, type: String
  field :expires_in, type: String
  field :token_type, type: String
  field :redirect_url, type: String, default: 'http://localhost:3000/'
  field :vendor_class, type: String, default: 'Zoho::Sign'
  
  belongs_to :booking_portal_client, class_name: 'Client'

  def vendor
    eval(self.vendor_class)
  end

  def authorization_url
    vendor.authorization_url(redirect_url)
  end

  def authorize_first_token!(code)
    vendor.authorize_first_token!(code, redirect_url, self)
  end

  def get_access_token
    vendor.refresh_token!(redirect_url, self)
    access_token
  end

  def test
    d = current_client.document_sign
    options = d.vendor.create("test.txt", d, {}).with_indifferent_access
    d.vendor.sign(d, options[:request_id], options[:action_id], options[:document_id])
    d.vendor.remind(d, res[:request_id])
    d.vendor.download(d, res[:request_id], res[:document_id])
    d.vendor.recall(d, res[:request_id])
  end
end