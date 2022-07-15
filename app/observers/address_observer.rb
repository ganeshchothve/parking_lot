class AddressObserver < Mongoid::Observer
  def before_validation address
    address.booking_portal_client_id = address.addressable.booking_portal_client.id
  end
end