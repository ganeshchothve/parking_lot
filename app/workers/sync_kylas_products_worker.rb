require 'spreadsheet'
class SyncKylasProductsWorker
  include Sidekiq::Worker

  def perform client_id
    client = Client.where(id: client_id).first
    if client.present?
      client.set(sync_product: false)
      kylas_products = Kylas::FetchProducts.new(User.new(booking_portal_client: client)).call(detail_response: true)
      if kylas_products.present?
        kylas_products.each do |kylas_product|
          kylas_product = kylas_product.with_indifferent_access
          mp_product = find_product_in_kylas(kylas_product[:id])
          if mp_product.blank?
            project = Project.new(
                name: kylas_product[:name],
                creator: client.users.admin.first,
                booking_portal_client: client,
                is_active: kylas_product[:isActive],
                kylas_product_id: kylas_product[:id].to_s
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
      client.set(sync_product: true)
    end
  end

  def find_product_in_kylas(kylas_product_id)
    project = Project.where(kylas_product_id: kylas_product_id).first
    booking_project_unit = BookingDetail.where(kylas_product_id: kylas_product_id).first
    result = (project || booking_project_unit)
    result
  end
end
