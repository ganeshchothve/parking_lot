class GenerateCoBrandingTemplatesWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'event'

  def perform(user_id, changes={})
    user = User.where(id: user_id).first
    if user.present?
      co_branding_asset_types = ['first_page_co_branding', 'last_page_co_branding']
      user_asset = Asset.where(assetable_id: user_id).in(document_type: co_branding_asset_types)
      
      co_branding_asset_types.each do |cbt|
        user_asset = Asset.where(assetable_id: user_id, document_type: cbt).first
        if user_asset.present?
          if (changes.keys & %w(first_name last_name email phone address company_name rera_id pan_number))
            user_asset.remove_file!

            co_branded_assets = Asset.where(assetable_id: user_id, document_type: 'co_branded_asset')
            co_branded_assets.each do |co_branded_asset|
              co_branded_asset.destroy
            end

            pdf_content = Template::CoBrandingTemplate.where(name: user_asset.document_type ).first.parsed_content(user)
            pdf = WickedPdf.new.pdf_from_string(pdf_content)
            File.open("#{Rails.root}/tmp/#{user_asset}-#{user.id}.pdf", "wb") do |file|
              file << pdf
              user_asset.file = file
            end
            user_asset.save
          end
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
