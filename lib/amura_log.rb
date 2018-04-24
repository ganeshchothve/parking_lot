class AmuraLog
  def self.debug(message=nil, file_name="amura.log")
    # To make it more sense, keeping .log in file_name
    file_path = "#{Rails.root}/log/#{file_name}"
    @amura_log ||= Logger.new(file_path)
    @amura_log.debug(message) unless message.nil?
  end
end