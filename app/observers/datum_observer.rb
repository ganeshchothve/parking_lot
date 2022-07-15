class DatumObserver < Mongoid::Observer
  def before_validation data
    data.booking_portal_client_id = data.data_attributable.booking_portal_client_id
  end
end