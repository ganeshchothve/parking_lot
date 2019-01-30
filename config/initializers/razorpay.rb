require "razorpay"
if Rails.env.production?
  Razorpay.setup(ENV_CONFIG['razorpay']['key'], ENV_CONFIG['razorpay']['secret'])
# else
  # Razorpay.setup('rzp_test_NTQGRS3ia0hiWY', 'pzM04pY4CJFkHbM3iWKBjDhN')
end
