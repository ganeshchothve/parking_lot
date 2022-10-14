module Api
  module KylasUsersConcern
    extend ActiveSupport::Concern

    def register_or_update_sales_user
      @user = User.where(kylas_user_id: params.dig("entity", "id")).first
      if @user.blank?
        sales_user_params = {
          first_name: params.dig("entity", "firstName"),
          last_name: params.dig("entity", "lastName"),
          email: params.dig("entity", "email"),
          phone: params.dig("entity", "phoneNumbers")[0].dig("dialCode") + params.dig("entity", "phoneNumbers")[0].dig("value"),
          role: 'sales',
          is_active_in_kylas: params.dig("entity", "active"),
          kylas_user_id: params.dig("entity", "id"),
          booking_portal_client: @client
        }
        @user = User.new(sales_user_params)
        @user.skip_confirmation_notification!
      else
        @user.assign_attributes(
          first_name:params.dig("entity", "firstName") ,
          last_name: params.dig("entity", "lastName"),
          phone: params.dig("entity", "phoneNumbers")[0].dig("dialCode") + params.dig("entity", "phoneNumbers")[0].dig("value"),
          email: params.dig("entity", "email"),
          is_active_in_kylas: params.dig("entity", "active")
        )
        @user.skip_confirmation_notification!
      end
    end
  end
end