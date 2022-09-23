require 'spreadsheet'
class SyncKylasProductsWorker
  include Sidekiq::Worker

  def perform user_id
    user = User.where(id: user_id).first
    client = user.booking_portal_client
    client.set(sync_product: false)
    if user.present?
      kylas_products = Kylas::FetchProducts.new(user).call
      if kylas_products.present?
        kylas_products.each do |kylas_product|
          mp_product = find_product_in_kylas(kylas_product[1].to_s)
          if !mp_product.present?
            project = Project.new(
              name: kylas_product[0],
              creator: user,
              booking_portal_client: user.booking_portal_client
              )
            project.save
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
  end
end