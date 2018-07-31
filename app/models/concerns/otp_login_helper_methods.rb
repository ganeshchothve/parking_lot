module OtpLoginHelperMethods
  def self.included base
    base.extend ClassMethods
    base.include InstanceMethods

    base.field :last_otp_sent_at, type: Time
    base.field :resend_otp_counter, type: Integer
    base.field :last_otp_login_attempt, type: Time
    base.field :otp_login_locked, type: Boolean, default: false
  end

  module ClassMethods
    def otp_resend_max_limit
      @@otp_resend_max_limit ||= 4
    end

    def otp_resend_wait_time
      @@otp_resend_wait_time ||= 15
    end

    def otp_locked_time
      @@otp_locked_time ||= 900
    end
  end

  module InstanceMethods

    def send_otp
      otp_sent_status = self.can_send_otp?

      if otp_sent_status[:status]
        SMSWorker.perform_async(self.phone, "Your OTP for login is #{self.otp_code}. ")
        self.set({last_otp_sent_at: Time.now, resend_otp_counter: (self.resend_otp_counter.present? ? self.resend_otp_counter : 0 )+ 1})
      end
      otp_sent_status
    end

    def check_otp_limit
      self.resend_otp_counter.present? && self.resend_otp_counter >= self.class.otp_resend_max_limit
    end

    def check_otp_duration
      self.last_otp_sent_at.present? && (Time.now.to_i - self.last_otp_sent_at.to_i) < self.class.otp_resend_wait_time
    end

    def can_send_otp?
      valid = true
      error_message = ""

      if self.check_otp_limit
        valid = false
        error_message = "Maximum limit reached to resend OTP code."
      end

      if self.check_otp_duration
        valid = false
        error_message = "Please wait for #{self.class.otp_resend_wait_time} seconds to resend OTP."
      end

      if self.otp_login_locked
        valid = false
        error_message = "Your OTP login is locked for #{self.class.otp_locked_time / 60} min. Please try again after #{Time.parse(self.last_otp_sent_at.to_i + self.class.otp_locked_time)}"
      end
      {status: valid, error: error_message}
    end

    def successful_otp_login
      self.set({
        last_otp_sent_at: nil,
        resend_otp_counter: nil,
        last_otp_login_attempt: nil,
        otp_login_locked: false
      })
    end
  end
end
