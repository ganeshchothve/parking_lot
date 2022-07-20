class AddressObserver < Mongoid::Observer
  def before_validation address
    if address.addressable.is_a?(Client)
      address.booking_portal_client_id = address.addressable.id
    else
      address.booking_portal_client_id = address.addressable.booking_portal_client.id
    end
  end
end