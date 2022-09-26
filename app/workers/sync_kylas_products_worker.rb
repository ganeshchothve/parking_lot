require 'spreadsheet'
class SyncKylasProductsWorker
  include Sidekiq::Worker

  def perform user_id
    user = User.where(id: user_id).first
    client = user.booking_portal_client
    client.set(sync_product: false)
    if user.present?
      kylas_products = Kylas::FetchProducts.new(user).call(detail_response: true)
      if kylas_products.present?
        kylas_products.each do |kylas_product|
          kylas_product = kylas_product.with_indifferent_access
          mp_product = find_product_in_kylas(kylas_product[:id])
          if mp_product.blank?
            project = Project.new(
                name: kylas_product[:name],
                creator: user,
                booking_portal_client: user.booking_portal_client,
                is_active: kylas_product[:isActive]
            )
            project.save
          else
            if mp_product.is_a?(Project)
              mp_product.assign_attributes(name: kylas_product[:name], is_active: kylas_product[:isActive])
              mp_product.save
            end
          end
        end
      end
    end
    client.set(sync_product: true)
  end

  def find_product_in_kylas(kylas_product_id)
    project = Project.where(kylas_product_id: kylas_product_id).first
    booking_project_unit = BookingDetail.where(kylas_product_id: kylas_product_id).first
    result = (project || booking_project_unit)
    result
  end
end