module PaymentGatewayService
  class CCAvenue < Default
    def build_parameters(search_id)
      search = Search.where(id: search_id).first
      payload = ""
      payload += "merchant_id=#{payment_profile[:merchant_id]}&"
      payload += "amount=" + @receipt.total_amount.to_s + "&"
      payload += "order_id=" + @receipt.receipt_id.to_s + "&"
      payload += "currency=INR&"
      payload += "language=EN&"
      payload += "redirect_url=#{redirect_url(search_id)}&"
      payload += "cancel_url=#{cancel_url(search_id)}&"
      payload += "sub_account_id=#{ENV_CONFIG['ccavenue']['sub_account_id']}&" if search.present? && search.project_unit.present? && ENV_CONFIG['ccavenue']['sub_account_eligible_project_towers'].include?(search.project_unit.project_tower_id.to_s)
      crypto = PaymentGatewayService::CCAvenueCrypto.new
      encrypted_data = crypto.encrypt(payload, payment_profile[:working_key])
      return encrypted_data
    end

    def gateway_url(search_id)
      return "/dashboard/user/searches/#{search_id}/gateway-payment/#{@receipt.receipt_id}"
    end

    def response_handler! params
      if Rails.env.development?
        @receipt.status = params[:status]
        @receipt.tracking_id = SecureRandom.hex
        @receipt.payment_identifier = SecureRandom.hex
        @receipt.status_message = ""
      else
        encResponse = params[:encResp]
        crypto = PaymentGatewayService::CCAvenueCrypto.new
        decResp = crypto.decrypt(encResponse, payment_profile[:working_key])
        decResp = decResp.split("&") rescue []
        decResp.each do |key|
          if key.from(0).to(key.index("=")-1) == 'order_status'
            status = key.from(key.index("=")+1).to(-1).downcase
            if(status.downcase == "success")
              @receipt.clearance_pending!
              @receipt.status_message = "success"
            else
              @receipt.failed if %w[pending clearance_pending].include? @receipt.status
            end
          end
          if key.from(0).to(key.index("=")-1) == 'tracking_id'
            @receipt.tracking_id = key.from(key.index("=")+1).to(-1)
          end
          if key.from(0).to(key.index("=")-1) == 'bank_ref_no'
            @receipt.payment_identifier = key.from(key.index("=")+1).to(-1)
          end
          if key.from(0).to(key.index("=")-1) == 'failure_message'
            @receipt.status_message = key.from(key.index("=")+1).to(-1).downcase
          end
          if key.from(0).to(key.index("=")-1) == 'order_id'
            @receipt.id.to_s == key.from(key.index("=")+1).to(-1)
          else
            # TODO: Raise an error email to us. Tampered data
          end
        end
      end
      @receipt.save
    end

    def payment_profile
      @receipt.account.as_json(only: %w(merchant_id working_key access_code)).with_indifferent_access
    end

    def redirect_url(search_id)
      "#{protocol}://#{@receipt.booking_portal_client.base_domain}/payment/#{@receipt.receipt_id}/process_payment/success"
    end

    def cancel_url(search_id)
      "#{protocol}://#{@receipt.booking_portal_client.base_domain}/payment/#{@receipt.receipt_id}/process_payment/failure"
    end

    def ccavenue_url
      if Rails.env.production?
        return "https://secure.ccavenue.com/transaction/transaction.do?command=initiateTransaction"
      elsif Rails.env.development?
        return "https://test.ccavenue.com/transaction/transaction.do?command=initiateTransaction"
      else
        return "https://test.ccavenue.com/transaction/transaction.do?command=initiateTransaction"
      end
    end

    def protocol
      Rails.application.config.action_mailer.default_url_options[:protocol]
    end
  end

  class CCAvenueCrypto
    INIT_VECTOR = (0..15).to_a.pack("C*")

    def encrypt(plain_text, key)
      secret_key =  [Digest::MD5.hexdigest(key)].pack("H*")
      cipher = OpenSSL::Cipher::Cipher.new('aes-128-cbc')
      cipher.encrypt
      cipher.key = secret_key
      cipher.iv  = INIT_VECTOR
      encrypted_text = cipher.update(plain_text) + cipher.final
      return (encrypted_text.unpack("H*")).first
    end

    def decrypt(cipher_text,key)
      secret_key =  [Digest::MD5.hexdigest(key)].pack("H*")
      encrypted_text = [cipher_text].pack("H*")
      decipher = OpenSSL::Cipher::Cipher.new('aes-128-cbc')
      decipher.decrypt
      decipher.key = secret_key
      decipher.iv  = INIT_VECTOR
      decrypted_text = (decipher.update(encrypted_text) + decipher.final).gsub(/\0+$/, '')
      return decrypted_text
    end
  end
end
