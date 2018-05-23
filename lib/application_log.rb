class ApplicationLog
  def self.log(message, payload={}, request_data={})
    file_path = "#{Rails.root}/log/app.log"
    payload[:timestamp] = Time.now
    if message.present?
      @log ||= Logger.new(file_path)
      str = "message: #{message}"
      str += " | request: #{request_data.to_json}" if request_data.present?
      str += " | payload: #{payload.to_json}"
      @log.warn(str)
    end
  end

  def self.user_log(resource_id, action, request_data={})
    file_path = "#{Rails.root}/log/app.log"
    @log ||= Logger.new(file_path)
    str = "message: User #{action}"
    str += " | request: #{request_data.to_json}" if request_data.present?
    str += " | payload: #{ {timestamp: Time.now, user_id: resource_id}.to_json }"
    @log.warn(str)
  end
end
