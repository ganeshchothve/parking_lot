if Rails.env == "production"
  ESTATE_SELL_DO_ID = '39b5807e744c47d3882cefb7f9b93a347fbd2a13b37f6b077e2f12ffa4f08a17'
  ESTATE_SELL_DO_SECRET = '6b50fc053b1dd72b6a116b2f1f5d8041ac41880e7e0304444dd2b9ade78b7f4d'
  ESTATE_SELL_DO_APP_URL = 'https://app.sell.do'
elsif Rails.env == "staging"
  ESTATE_SELL_DO_ID = 'b7666bd268d40761a17967395b720db601b4f32497c277ab35c7e7424e356c41'
  ESTATE_SELL_DO_SECRET = 'a348563bfd1f2aea63466436a1b7c89e4d1a1305444ddd68725535531e43ab21'
  ESTATE_SELL_DO_APP_URL = 'https://v3.sell.do'
else
  ESTATE_SELL_DO_ID = '1058e8374d972347344c6ee6c8b9d4dd286f66fdebdee6b611d2ed334493a356'
  ESTATE_SELL_DO_SECRET = 'd4f705fec6104f943b014f5612bcfef4f470c5645227dcb3d7ee05fc1226e2e9'
  ESTATE_SELL_DO_APP_URL = 'http://localhost:8888'
end

if Rails.env.development? || Rails.env.test? || Rails.env.staging?
  APP_KYLAS_HOST = 'https://api-qa.sling-dev.com'
elsif Rails.env.production?
  APP_KYLAS_HOST = 'https://api.kylas.io'
end

APP_KYLAS_VERSION = 'v1'


SUPPORT_NEW_PRODUCT_CRM_LINK = 'https://support.kylas.io/portal/en/kb/articles/add-products-services'