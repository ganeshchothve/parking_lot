require "razorpay"
if Rails.env.production?
  Razorpay.setup(ENV_CONFIG['razorpay']['key'], ENV_CONFIG['razorpay']['secret'])
else
  Razorpay.setup('rzp_test_bMV0Fp1FW4KQwy', 'obAjJRSWKB4k5dxAazcQeivw')
end
