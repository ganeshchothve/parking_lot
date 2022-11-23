module SchemesHelper
  def custom_schemes_path
    current_user.buyer? ? buyer_schemes_path : admin_schemes_path
  end

  def filter_scheme_options(scheme_id=nil)
    if scheme_id.present?
      Scheme.where(booking_portal_client_id: current_client.try(:id), _id: scheme_id).map{|pt| [pt.name, pt.id]}
    else
      []
    end
  end
end
