module UserKycsHelper
  def custom_user_kycs_path
    current_user.buyer? ? buyer_user_kycs_path : admin_user_kycs_path
  end

  def preferred_floors_options(kyc)
    options_for_select((kyc.preferred_floors + (I18n.t("mongoid.attributes.project_unit.floor_bands").keys.map(&:to_s) - kyc.preferred_floors)).collect{ |count| [t("mongoid.attributes.project_unit.floor_bands.#{count}", default: 'Other'), count] }, kyc.preferred_floors)
  end
end
