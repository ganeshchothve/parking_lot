class AmuraLog
  def self.debug(message=nil, file_name="amura.log", options={})
    # To make it more sense, keeping .log in file_name
    file_path = "#{Rails.root}/log/#{file_name}"
    @amura_log ||= Logger.new(file_path)
    if options[:payload].present?
      @amura_log.warn("----------------------PAYLOAD-------------------------------") unless message.nil?
      @amura_log.warn(options[:payload])
    end
    @amura_log.warn("------------------------RESPONSE-----------------------------------") unless message.nil?
    @amura_log.warn(message) unless message.nil?
  end
end
