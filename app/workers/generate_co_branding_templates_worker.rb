class GenerateCoBrandingTemplatesWorker
  include Sidekiq::Worker

  def perform(user_id)
    user = User.where(id: user_id).first
    if user.present?
      co_branding_asset_types = ['first_page_co_branding', 'last_page_co_branding']
      user_asset = Asset.where(assetable_id: user_id).in(document_type: co_branding_asset_types)
      
      co_branding_asset_types.each do |cbt|
        user_asset = Asset.where(assetable_id: user_id, document_type: cbt).first
        if user_asset.present?
          user_asset.remove_file!

          co_branded_assets = Asset.where(assetable_id: user_id, document_type: 'co_branded_asset')
          co_branded_assets.destroy_all

          pdf_content = Template::CoBrandingTemplate.where(name: user_asset.document_type ).first.parsed_content(user)
          options = {
            orientation: 'Landscape',
            page_width: '2000',
            dpi: '300'
          }
          pdf = WickedPdf.new.pdf_from_string(pdf_content, options)
          File.open("#{Rails.root}/tmp/#{user_asset}-#{user.id}.pdf", "wb") do |file|
            file << pdf
            user_asset.file = file
          end
          user_asset.save
        else
          asset = user.assets.build(document_type: cbt, assetable: user, assetable_type: user.class.to_s)
          pdf_content = Template::CoBrandingTemplate.where(name: cbt).first.parsed_content(user)
          pdf = WickedPdf.new.pdf_from_string(pdf_content)
          File.open("#{Rails.root}/tmp/#{cbt}-#{user.id}.pdf", "wb") do |file|
            file << pdf
            asset.file = file
          end
          asset.save
        end
      end
    end
  end
end
